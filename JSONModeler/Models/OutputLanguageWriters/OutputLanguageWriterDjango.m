//
// Copyright 2016 The Nerdery, LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "OutputLanguageWriterDjango.h"
#import "ClassBaseObject.h"

#import "NSString+Nerdery.h"

static NSUInteger kDjangoModelMaxTextLength = 255;

@interface OutputLanguageWriterDjango () {
@private
    
}

- (NSString *)pythonFileForClassObjects:(NSArray *)classObjects;

@end

@implementation OutputLanguageWriterDjango

- (BOOL)writeClassObjects:(NSDictionary *)classObjectsDict toURL:(NSURL *)url options:(NSDictionary *)options generatedError:(BOOL *)generatedErrorFlag {
    
    BOOL filesHaveHadError = NO;
    BOOL filesHaveBeenWritten = NO;
    
    NSArray *classObjects = classObjectsDict.allValues;
    
    for (ClassBaseObject *base in classObjects) {
        if ([base.className isEqualToString:@"InternalBaseClass"]) {
            NSString *newBaseClassName;
            
            if (nil != options[kDjangoWritingOptionBaseClassName]) {
                newBaseClassName = options[kDjangoWritingOptionBaseClassName];
            } else {
                newBaseClassName = @"DataModel";
            }
            BOOL hasUniqueFileNameBeenFound = NO;
            NSUInteger classCheckInteger = 2;
            
            while (hasUniqueFileNameBeenFound == NO) {
                hasUniqueFileNameBeenFound = YES;
                
                for (ClassBaseObject *collisionBaseObject in classObjects) {
                    if ([collisionBaseObject.className isEqualToString:newBaseClassName]) {
                        hasUniqueFileNameBeenFound = NO; 
                    }
                }
                
                if (hasUniqueFileNameBeenFound == NO) {
                    newBaseClassName = [NSString stringWithFormat:@"%@%li", newBaseClassName, classCheckInteger];
                    classCheckInteger++;
                }
            }
            
            base.className = newBaseClassName;
        }
    }
    
    
    NSString *pyFile = [self pythonFileForClassObjects:classObjects];
    
    NSError *error;
    [pyFile writeToURL:[url URLByAppendingPathComponent:@"jsonModel.py"] atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        filesHaveHadError = YES;
    } else {
        filesHaveBeenWritten = YES;
    }
    
    *generatedErrorFlag = filesHaveHadError;
    
    return filesHaveBeenWritten;
    
}

- (NSString *)pythonFileForClassObjects:(NSArray *)classObjects {
    /* Reconstruct the classes so that relationships are in the child class, not parent */
    NSMutableDictionary *pythonClasses = [[NSMutableDictionary alloc] init];
    
    for (ClassBaseObject *classObject in classObjects) {
        if (nil == pythonClasses[classObject.className]) {
            NSMutableDictionary *pythonClass = [[NSMutableDictionary alloc] init];
            pythonClasses[classObject.className] = pythonClass;
        }
        
        NSMutableDictionary *pythonClass = pythonClasses[classObject.className];
        
        for (ClassPropertiesObject *property in classObject.properties.allValues) {
            PropertyType type = property.type;
            
            if (type == PropertyTypeString) {
                pythonClass[property.name] = @"string";
            } else if (type == PropertyTypeInt) {
                pythonClass[property.name] = @"int";
            } else if (type == PropertyTypeDouble) {
                pythonClass[property.name] = @"double";
            } else if (type == PropertyTypeBool) {
                pythonClass[property.name] = @"bool";
            } else if (type == PropertyTypeClass) {
                /* Add a one-to-one relationship to the child class */
                if (nil == pythonClasses[[property.name uppercaseCamelcaseString]]) {
                    NSMutableDictionary *childClass = [[NSMutableDictionary alloc] init];
                    pythonClasses[[property.name uppercaseCamelcaseString]] = childClass;
                }
                NSMutableDictionary *childClass = pythonClasses[[property.name uppercaseCamelcaseString]];
                childClass[[NSString stringWithFormat:@"oneToOne%@", classObject.className]] = classObject.className;
            } else if (type == PropertyTypeArray) {
                /* Add a many-to-one relationship to the child class */
                if (nil == pythonClasses[[property.name uppercaseCamelcaseString]]) {
                    NSMutableDictionary *childClass = [[NSMutableDictionary alloc] init];
                    pythonClasses[[property.name uppercaseCamelcaseString]] = childClass;
                }
                NSMutableDictionary *childClass = pythonClasses[[property.name uppercaseCamelcaseString]];
                childClass[[NSString stringWithFormat:@"manyToOne%@", classObject.className]] = classObject.className;
                
                if (property.collectionType == PropertyTypeInt) {
                    childClass[property.name] = @"int";
                } else if (property.collectionType == PropertyTypeDouble) {
                    childClass[property.name] = @"double";
                } else if (property.collectionType == PropertyTypeString) {
                    childClass[property.name] = @"string";
                } else if (property.collectionType == PropertyTypeBool) {
                    childClass[property.name] = @"bool";
                }
            }
        }
    }
    
    NSMutableString *fileString = [NSMutableString stringWithString:@"from django.db import models\n"];
    
    
    
    for (NSString *className in pythonClasses) {
        [fileString appendFormat:@"\nclass %@(models.Model):\n", className];
        NSDictionary *properties = pythonClasses[className];
        
        for (NSString *property in properties) {
            /* If it's a simple type, define the database column type */
            NSString *type = properties[property];
            
            if ([type isEqualToString:@"string"]) {
                [fileString appendFormat:@"\t%@ = models.CharField(max_length=%lu, blank=True)\n", [property underscoreDelimitedString], kDjangoModelMaxTextLength];
            } else if ([type isEqualToString:@"int"]) {
                [fileString appendFormat:@"\t%@ = models.IntegerField(blank=True, null=True)\n", [property underscoreDelimitedString]];
            } else if ([type isEqualToString:@"double"]) {
                [fileString appendFormat:@"\t%@ = models.FloatField(blank=True)\n", [property underscoreDelimitedString]];
            } else if ([type isEqualToString:@"bool"]) {
                [fileString appendFormat:@"\t%@ = models.BooleanField(blank=True, null=True)\n", [property underscoreDelimitedString]];
            } else {
                /* ...otherwise, make a relationship */
                if ([property hasPrefix:@"oneToOne"]) {
                    [fileString appendFormat:@"\t%@ = models.OneToOneField(\"%@\", blank=True)\n", [properties[property] underscoreDelimitedString], properties[property]];
                } else if ([property hasPrefix:@"manyToOne"]) {
                    [fileString appendFormat:@"\t%@ = models.ForeignKey(\"%@\", blank=True)\n", [properties[property] underscoreDelimitedString], properties[property]];
                } else {
                    NSLog(@"%@ : %@->%@", className, property, properties[property]);
                }
            }
        }
        [fileString appendString:@"\n"];
    }
    
    return fileString;
    
}

#pragma mark - Reserved Words Methods

- (NSSet *)reservedWords {
    return [NSSet setWithObjects:@"and", @"assert", @"break", @"class", @"continue", @"def", @"del", @"elif", @"else", @"except", @"exec", @"finally", @"for", @"from", @"global",  @"id", @"if", @"import", @"in", @"is", @"lambda", @"not", @"or", @"pass", @"print", @"raise", @"return", @"try", @"type", @"while", @"yield", nil];
}

- (NSString *)classNameForObject:(ClassBaseObject *)classObject fromReservedWord:(NSString *)reservedWord {
    NSString *className = [[reservedWord stringByAppendingString:@"Class"] capitalizeFirstCharacter];
    NSRange startsWithNumeral = [[className substringToIndex:1] rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789"]];
    
    if ( !(startsWithNumeral.location == NSNotFound && startsWithNumeral.length == 0) ) {
        className = [@"Num" stringByAppendingString:className];
    }
    
//    NSMutableArray *components = [[className componentsSeparatedByString:@"_"] mutableCopy];
//    
//    NSInteger numComponents = components.count;
//    
//    for (int i = 0; i < numComponents; ++i) {
//        components[i] = [(NSString *)components[i] capitalizeFirstCharacter];
//    }
//    return [components componentsJoinedByString:@""];
  
  return className;

}

- (NSString *)propertyNameForObject:(ClassPropertiesObject *)propertyObject inClass:(ClassBaseObject *)classObject fromReservedWord:(NSString *)reservedWord {
    NSString *propertyName = [[reservedWord stringByAppendingString:@"Property"] uncapitalizeFirstCharacter];
    NSRange startsWithNumeral = [[propertyName substringToIndex:1] rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789"]];
    
    if ( !(startsWithNumeral.location == NSNotFound && startsWithNumeral.length == 0) ) {
        propertyName = [@"num" stringByAppendingString:propertyName];
    }
    return [propertyName uncapitalizeFirstCharacter];
}

@end
