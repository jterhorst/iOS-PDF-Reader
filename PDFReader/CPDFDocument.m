//
//  CPDFDocument.m
//  PDFReader
//
//  Created by Jonathan Wight on 02/19/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "CPDFDocument.h"

#import "CPDFDocument_Private.h"
#import "CPDFPage.h"

@interface CPDFDocument ()
@property (readwrite, assign) dispatch_queue_t queue;

- (void)startGeneratingThumbnails;
@end

#pragma mark -

@implementation CPDFDocument

@synthesize URL;
@synthesize cg;
@synthesize delegate;

@synthesize queue;

- (id)initWithURL:(NSURL *)inURL;
	{
	if ((self = [super init]) != NULL)
		{
        URL = [inURL retain];
        
        cg = CGPDFDocumentCreateWithURL((CFURLRef)self.URL);

        [self startGeneratingThumbnails];
		}
	return(self);
	}
    
- (void)dealloc
    {
    if (queue != NULL)
        {
        dispatch_release(queue);
        queue = NULL;
        }
    
    [URL release];
    URL = NULL;
    
    if (cg)
        {
        CGPDFDocumentRelease(cg);
        cg = NULL;
        }
    //
    [super dealloc];
    }
    
- (NSUInteger)numberOfPages
    {
    return(CGPDFDocumentGetNumberOfPages(self.cg));
    }
    
- (CPDFPage *)pageForPageNumber:(NSInteger)inPageNumber
    {
    NSString *theKey = [NSString stringWithFormat:@"page_%d", inPageNumber];
    CPDFPage *thePage = [self.cache objectForKey:theKey];
    if (thePage == NULL)
        {
        thePage = [[[CPDFPage alloc] initWithDocument:self pageNumber:inPageNumber] autorelease];
        [self.cache setObject:thePage forKey:theKey];
        }
    return(thePage);
    }

- (void)startGeneratingThumbnails
    {
//    self.thumbnailCache = [[[NSCache alloc] init] autorelease];

    const size_t theNumberOfPages = CGPDFDocumentGetNumberOfPages(self.cg);

    queue = dispatch_queue_create("com.example.MyQueue", NULL);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {

        dispatch_apply(theNumberOfPages, self.queue, ^(size_t inIndex) {

            const size_t thePageNumber = inIndex + 1;
            
            CPDFPage *thePage = [self pageForPageNumber:thePageNumber];

            if ([self.cache objectForKey:[NSNumber numberWithInteger:thePageNumber]] == NULL)
                {
                UIImage *theImage = [thePage imageWithSize:(CGSize){ 128, 128 }];
                [self.cache setObject:theImage forKey:[NSNumber numberWithInteger:thePageNumber]];
                }

            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.delegate PDFDocument:self didUpdateThumbnailForPage:thePage];
                });
            });
        });
    }

- (void)stopGeneratingThumbnails
    {
    }



@end
