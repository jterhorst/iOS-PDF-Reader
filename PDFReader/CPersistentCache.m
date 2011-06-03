//
//  CPersistentCache.m
//  PDFReader
//
//  Created by Jonathan Wight on 06/02/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "CPersistentCache.h"

#define CACHE_VERSION 1

@interface CPersistentCache ()
@property (readwrite, nonatomic, retain) NSCache *cache;
@property (readwrite, nonatomic, retain) NSURL *URL;
@end

#pragma mark -

@implementation CPersistentCache

@synthesize name;

@synthesize cache;
@synthesize URL;

- (id)initWithName:(NSString *)inName
	{
	if ((self = [super init]) != NULL)
		{
        name = [inName retain];
        cache = [[NSCache alloc] init];
		}
	return(self);
	}

- (void)dealloc
    {
    [name release];
    
    [cache release];
    [URL release];
    //
    [super dealloc];
    }
    
- (NSURL *)URL
    {
    if (URL == NULL)
        {
        NSURL *theURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
        theURL = [theURL URLByAppendingPathComponent:@"PersistentCache"];
        theURL = [theURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%d", CACHE_VERSION]];
        theURL = [theURL URLByAppendingPathComponent:self.name];
        URL = [theURL retain];
        }
    return(URL);
    }
    
    
- (id)objectForKey:(id)key
    {
    id theObject = NULL;
    theObject = [self.cache objectForKey:key];
    if (theObject == NULL)
        {
        NSURL *theMetadataURL = [[self.URL URLByAppendingPathComponent:key] URLByAppendingPathExtension:@"metadata.plist"];
        
        NSDictionary *theMetadata = [NSDictionary dictionaryWithContentsOfURL:theMetadataURL];
        if (theMetadata != NULL)
            {
            NSURL *theDataURL = [self.URL URLByAppendingPathComponent:[theMetadata objectForKey:@"href"]];
            NSUInteger theCost = [[theMetadata objectForKey:@"cost"] unsignedIntegerValue];
            
            NSData *theData = [NSData dataWithContentsOfURL:theDataURL options:NSDataReadingMapped error:NULL];
            
            theObject = [UIImage imageWithData:theData];
            
            [self.cache setObject:theObject forKey:key cost:theCost];
            }
        }
    
    return(theObject);
    }

- (void)setObject:(id)obj forKey:(id)key
    {
    [self setObject:obj forKey:key cost:0];
    }
    
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g
    {
    [self.cache setObject:obj forKey:key cost:g];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.URL.path] == NO)
            {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.URL.path withIntermediateDirectories:YES attributes:NULL error:NULL];
            }
        NSURL *theURL = [self.URL URLByAppendingPathComponent:key];
        
        BOOL theWriteFlag = NO;
        
        NSURL *theDataURL = NULL;
        
        if ([obj isKindOfClass:[UIImage class]])
            {
            theDataURL = [theURL URLByAppendingPathExtension:@"png"];
            NSData *theData = UIImagePNGRepresentation(obj);
            [theData writeToURL:theDataURL options:0 error:NULL];
            theWriteFlag = YES;
            }
            
        if (theWriteFlag == YES)
            {
            NSDictionary *theMetadata = [NSDictionary dictionaryWithObjectsAndKeys:
                [theDataURL lastPathComponent], @"href",
                [NSNumber numberWithUnsignedInteger:g], @"cost",
                NULL];

            NSData *theData = [NSPropertyListSerialization dataWithPropertyList:theMetadata format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
            [theData writeToURL:[theURL URLByAppendingPathExtension:@"metadata.plist"] options:0 error:NULL];
            }
        });
    }

- (void)removeObjectForKey:(id)key
    {
    [self.cache removeObjectForKey:key];
    }

@end
