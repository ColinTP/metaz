//
//  APWriteManager.h
//  MetaZ
//
//  Created by Brian Olsen on 29/09/09.
//  Copyright 2009 Maven-Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MetaZKit/MetaZKit.h>
#import "APDataProvider.h"

@interface APChapterWriteTask : MZTaskOperation
{
    NSString* chaptersFile;
}
+ (id)taskWithFileName:(NSString *)fileName chaptersFile:(NSString *)chaptersFile;
- (id)initWithFileName:(NSString *)fileName chaptersFile:(NSString *)chaptersFile;

@end

@interface APWriteOperationsController : MZOperationsController
{
    id<MZDataWriteDelegate> delegate;
    APDataProvider* provider;
    MetaEdits* edits;
}

+ (id)controllerWithProvider:(id<MZDataProvider>)provider
                    delegate:(id<MZDataWriteDelegate>)delegate
                       edits:(MetaEdits *)edits;

- (id)initWithProvider:(id<MZDataProvider>)provider
              delegate:(id<MZDataWriteDelegate>)delegate
                 edits:(MetaEdits *)edits;

- (void)operationsFinished;
- (void)notifyPercent:(NSInteger)percent;

@end

@interface APMainWriteTask : MZTaskOperation
{
    APWriteOperationsController* controller;
    NSString* pictureFile;
}

+ (id)taskWithController:(APWriteOperationsController*)controller
             pictureFile:(NSString *)file;
- (id)initWithController:(APWriteOperationsController*)controller
             pictureFile:(NSString *)file;

@end
