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


#import "ModelerDocument.h"
#import "MainWindowController.h"

@implementation ModelerDocument

- (instancetype)init {
    self = [super init];
    
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, return nil.
        _httpMethod = HTTPMethodGet;
        _httpHeaders = @[];
        _modeler = [[JSONModeler alloc] init];
    }
    
    return self;
}

- (instancetype)initWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    
    if ([typeName isEqualToString:@"JSONModelerType"]) {
        return [super initWithContentsOfURL:url ofType:typeName error:outError];
    }
    
    // Open a .json file
    self = [self init];
    
    if (self) {
        if ([typeName isEqualToString:@"JSONTextType"]) {
            _modeler = [[JSONModeler alloc] init];
            _modeler.JSONString = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:url] encoding:NSUTF8StringEncoding];
        }
    }
    
    return self;
}

- (void)makeWindowControllers {
    MainWindowController *mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"];
    [self addWindowController:mainWindowController];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    /*
     Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    */
    NSMutableData *outData = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:outData];
    
    [archiver encodeObject:_modeler forKey:@"modeler"];
    [archiver encodeInt:_httpMethod forKey:@"httpMethod"];
    [archiver encodeObject:_httpHeaders forKey:@"httpHeaders"];
    
    [archiver finishEncoding];
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    
    return outData;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    /*
    Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    */
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    self.modeler = [unarchiver decodeObjectForKey:@"modeler"];
    self.httpMethod = [unarchiver decodeIntForKey:@"httpMethod"];
    self.httpHeaders = [unarchiver decodeObjectForKey:@"httpHeaders"];
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    
    return YES;
}

- (BOOL)isDocumentEdited {
    return NO;
}

+ (BOOL)autosavesInPlace {
    return NO;
}

@end
