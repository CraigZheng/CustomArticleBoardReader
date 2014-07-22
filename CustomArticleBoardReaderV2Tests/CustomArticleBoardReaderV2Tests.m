//
//  CustomArticleBoardReaderV2Tests.m
//  CustomArticleBoardReaderV2Tests
//
//  Created by Craig on 9/02/2014.
//  Copyright (c) 2014 Craig. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "czzArticle.h"
#import "czzArticleProcessor.h"

@interface CustomArticleBoardReaderV2Tests : XCTestCase<czzArticleProcessorDelegate>
@property BOOL done;
@property czzArticle *articleToUpdate;
@end

@implementation CustomArticleBoardReaderV2Tests
@synthesize done;
@synthesize articleToUpdate;

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testArticleProcessor
{
    done = NO;
    NSError *error;
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"receivedHTMLBody" ofType:@"txt"];
    NSString *htmlBody = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"%@", error);
    } else {
        NSLog(@"Ready completed, %ld characters", (unsigned long)htmlBody.length);
    }
    articleToUpdate = [czzArticle new];
    czzArticleProcessor *processor = [[czzArticleProcessor alloc] initWithArticle:articleToUpdate andHTMLBody:htmlBody andDelegate:self];
    
    [self waitForCompletion: 3 * 60];
    XCTAssertNotEqual(articleToUpdate.htmlFragments.count, 0, @"HTML FRAGMENTS ARRAY EMPTY!");
}

- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];
    
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if([timeoutDate timeIntervalSinceNow] < 0.0)
            break;
    } while (!done);
    
    return done;
}

#pragma mark - czzArticleProcessorDelegate
-(void)articleUpdated:(czzArticle *)article isFinished:(BOOL)finished {
    NSLog(@"article updated: %d fragments, isFinished: %hhd", articleToUpdate.htmlFragments.count, finished);
    NSLog(@"last html fragment: %@", [articleToUpdate.htmlFragments.lastObject description]);
    done = finished;
}
@end
