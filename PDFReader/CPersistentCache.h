//
//  CPersistentCache.h
//  PDFReader
//
//  Created by Jonathan Wight on 06/02/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CPersistentCache : NSObject {
    
}

@property (readwrite, nonatomic, retain) NSString *name;

- (id)objectForKey:(id)key;
- (void)setObject:(id)obj forKey:(id)key;
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g;
- (void)removeObjectForKey:(id)key;

@end
