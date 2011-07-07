//
//  CPersistentCache.m
//  PDFReader
//
//  Created by Jonathan Wight on 06/02/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "CPersistentCache.h"

#import <MobileCoreServices/MobileCoreServices.h>

#define CACHE_VERSION 0

@interface CPersistentCache ()
@property (readwrite, nonatomic, retain) NSCache *cache;
@property (readwrite, nonatomic, retain) NSURL *URL;

- (BOOL)object:(id)inObject toData:(NSData **)outData type:(NSString **)outType error:(NSError **)outError;
- (BOOL)data:(NSData *)inData type:(NSString *)inType toObject:(id *)outObject error:(NSError **)outError;
@end

#pragma mark -

@implementation CPersistentCache

@synthesize name;
@synthesize converterBlock;
@synthesize reverseConverterBlock;

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
        theURL = [theURL URLByAppendingPathComponent:[NSString stringWithFormat:@"V%d", CACHE_VERSION]];
        theURL = [theURL URLByAppendingPathComponent:self.name];
        if ([[NSFileManager defaultManager] fileExistsAtPath:theURL.path] == NO)
            {
            [[NSFileManager defaultManager] createDirectoryAtPath:theURL.path withIntermediateDirectories:YES attributes:NULL error:NULL];
            }
        URL = [theURL retain];
        }
    return(URL);
    }
    
- (BOOL)containsObjectForKey:(id)key
    {
    id theObject = [self.cache objectForKey:key];
    if (theObject == NULL)
        {
        NSURL *theMetadataURL = [[self.URL URLByAppendingPathComponent:key] URLByAppendingPathExtension:@"metadata.plist"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:theMetadataURL.path] == YES)
            {
            return(YES);
            }
        }
    return(NO);
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
            if (theData)
                {
                NSString *theType = [theMetadata objectForKey:@"type"];            
                [self data:theData type:theType toObject:&theObject error:NULL];
                
                [self.cache setObject:theObject forKey:key cost:theCost];
                }
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
    
    NSURL *theURL = [self.URL URLByAppendingPathComponent:key];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        
        BOOL theWriteFlag = NO;
        
        NSURL *theDataURL = NULL;

        NSData *theData = NULL;
        NSString *theType = NULL;
        if ([self object:obj toData:&theData type:&theType error:NULL] == YES)
            {
            NSString *theFilenameExtension = [(NSString *)UTTypeCopyPreferredTagWithClass((CFStringRef)theType, kUTTagClassFilenameExtension) autorelease];
            theDataURL = [theURL URLByAppendingPathExtension:theFilenameExtension];
            [theData writeToURL:theDataURL options:0 error:NULL];
            theWriteFlag = YES;
            }
            
        if (theWriteFlag == YES)
            {
            NSDictionary *theMetadata = [NSDictionary dictionaryWithObjectsAndKeys:
                [theDataURL lastPathComponent], @"href",
                [NSNumber numberWithUnsignedInteger:g], @"cost",
                theType, @"type",
                NULL];

            NSData *theData = [NSPropertyListSerialization dataWithPropertyList:theMetadata format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
            [theData writeToURL:[theURL URLByAppendingPathExtension:@"metadata.plist"] options:0 error:NULL];
            }
        });
    }

- (void)removeObjectForKey:(id)key
    {
    [self.cache removeObjectForKey:key];
    
    NSURL *theMetadataURL = [[self.URL URLByAppendingPathComponent:key] URLByAppendingPathExtension:@"metadata.plist"];
    
    NSDictionary *theMetadata = [NSDictionary dictionaryWithContentsOfURL:theMetadataURL];
    if (theMetadata != NULL)
        {
        NSURL *theDataURL = [self.URL URLByAppendingPathComponent:[theMetadata objectForKey:@"href"]];
        
        [[NSFileManager defaultManager] removeItemAtURL:theMetadataURL error:NULL];
        [[NSFileManager defaultManager] removeItemAtURL:theDataURL error:NULL];
        }
    }

#pragma mark -

- (BOOL)object:(id)inObject toData:(NSData **)outData type:(NSString **)outType error:(NSError **)outError
    {
    BOOL theResult = NO;
    if ([inObject isKindOfClass:[UIImage class]] == YES)
        {
        if (outData)
            {
            *outData = UIImagePNGRepresentation(inObject);
            }
        if (outType)
            {
            *outType = (NSString *)kUTTypePNG;
            }
        theResult = YES;
        }
    else if ([inObject conformsToProtocol:@protocol(NSCoding)])
        {
        if (outData)
            {
            *outData = [NSKeyedArchiver archivedDataWithRootObject:inObject];
            }
        if (outType)
            {
            *outType = (NSString *)kUTTypeData;
            }
        theResult = YES;
        }
    else if (self.converterBlock != NULL)
        {
        theResult = self.converterBlock(inObject, outData, outType, outError);
        }

    return(theResult);
    }
    
- (BOOL)data:(NSData *)inData type:(NSString *)inType toObject:(id *)outObject error:(NSError **)outError
    {
    BOOL theResult = NO;
    if ([inType isEqualToString:(NSString *)kUTTypePNG])
        {
        if (outObject)
            {
            *outObject = [UIImage imageWithData:inData];
            }
        theResult = YES;
        }
    else if ([inType isEqualToString:(NSString *)kUTTypeData])
        {
        if (outObject)
            {
            *outObject = [NSKeyedUnarchiver unarchiveObjectWithData:inData];
            }
        theResult = YES;
        }
    else if (self.reverseConverterBlock != NULL)
        {
        theResult = self.reverseConverterBlock(inData, inType, outObject, outError);
        }

    return(theResult);
    }

@end
