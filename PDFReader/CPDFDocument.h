//
//  CPDFDocument.h
//  PDFReader
//
//  Created by Jonathan Wight on 02/19/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CPDFDocumentDelegate;

@class CPDFPage;

@interface CPDFDocument : NSObject {
    
}

@property (readonly, nonatomic, retain) NSURL *URL;
@property (readonly, nonatomic, assign) CGPDFDocumentRef cg;
@property (readonly, nonatomic, assign) NSUInteger numberOfPages;
@property (readwrite, nonatomic, assign) id <CPDFDocumentDelegate> delegate;

@property (readonly, nonatomic, retain) NSString *title;

- (id)initWithURL:(NSURL *)inURL;

- (CPDFPage *)pageForPageNumber:(NSInteger)inPageNumber;
@end

#pragma mark -

@protocol CPDFDocumentDelegate <NSObject>

- (void)PDFDocument:(CPDFDocument *)inDocument didUpdateThumbnailForPage:(CPDFPage *)inPage;

@end