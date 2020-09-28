#import "ReactNativeShareExtension.h"
#import "React/RCTRootView.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define URL_IDENTIFIER @"public.url"
#define IMAGE_IDENTIFIER @"public.image"
#define MOVIE_IDENTIFIER @"public.movie"
#define TEXT_IDENTIFIER (NSString *)kUTTypePlainText

NSExtensionContext* extensionContext;

@implementation ReactNativeShareExtension {
    NSTimer *autoTimer;
    NSString* type;
    NSString* value;
}

- (UIView*) shareView {
    return nil;
}

RCT_EXPORT_MODULE();

- (void)viewDidLoad {
    [super viewDidLoad];

    //object variable for extension doesn't work for react-native. It must be assign to gloabl
    //variable extensionContext. in this way, both exported method can touch extensionContext
    extensionContext = self.extensionContext;

    UIView *rootView = [self shareView];
    if (rootView.backgroundColor == nil) {
        rootView.backgroundColor = [[UIColor alloc] initWithRed:1 green:1 blue:1 alpha:0.1];
    }

    self.view = rootView;
}


RCT_EXPORT_METHOD(close) {
    [extensionContext completeRequestReturningItems:nil
                                  completionHandler:nil];
}



RCT_EXPORT_METHOD(openURL:(NSString *)url) {
  UIApplication *application = [UIApplication sharedApplication];
  NSURL *urlToOpen = [NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  [application openURL:urlToOpen options:@{} completionHandler: nil];
}



RCT_REMAP_METHOD(data,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    [self extractDataFromContext: extensionContext withCallback:^(NSMutableArray* val, NSString* contentType, NSException* err) {
        if(err) {
            reject(@"error", err.description, nil);
        } else {
            resolve(@{
                      @"type": contentType,
                      @"value": val
                      });
        }
    }];
}

- (void)extractDataFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSMutableArray *value, NSString* contentType, NSException *exception))callback {
    @try {
        NSExtensionItem *item = [context.inputItems firstObject];
        NSArray *attachments = item.attachments;
		__block NSMutableArray *items = [[NSMutableArray alloc] init];
		
		NSMutableDictionary *providers = [[NSMutableDictionary alloc] init];
		
		[providers setObject:[[NSMutableArray alloc] init] forKey:@"txt"];
		[providers setObject:[[NSMutableArray alloc] init] forKey:@"url"];
		[providers setObject:[[NSMutableArray alloc] init] forKey:@"image"];
		[providers setObject:[[NSMutableArray alloc] init] forKey:@"video"];
		
		for(NSItemProvider *provider in attachments)
		{
            if([provider hasItemConformingToTypeIdentifier:URL_IDENTIFIER])
                [[providers objectForKey:@"url"] addObject:provider];
			else if ([provider hasItemConformingToTypeIdentifier:TEXT_IDENTIFIER])
				[[providers objectForKey:@"txt"] addObject:provider];
            else if ([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER])
				[[providers objectForKey:@"image"] addObject:provider];
			else if([provider hasItemConformingToTypeIdentifier:MOVIE_IDENTIFIER])
				[[providers objectForKey:@"video"] addObject:provider];
		}
		
		if([providers[@"image"] count] > 0)
			for(NSItemProvider* provider in providers[@"image"])
			{
				[provider loadItemForTypeIdentifier:IMAGE_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
					NSURL *url = (NSURL *)item;
					
					[items addObject:[url absoluteString]];

					if(callback && [items count] == ([providers[@"txt"] count] + [providers[@"image"] count] + [providers[@"video"] count] + [providers[@"url"] count])) {
						callback(items, [[[url absoluteString] pathExtension] lowercaseString], nil);
					}
				}];
			}
		
		if([providers[@"video"] count] > 0)
			for(NSItemProvider* provider in providers[@"video"])
			{
				[provider loadItemForTypeIdentifier:MOVIE_IDENTIFIER options:nil completionHandler:^(NSURL* url, NSError *error) {
					[items addObject:[url absoluteString]];

					if(callback && [items count] == ([providers[@"txt"] count] + [providers[@"image"] count] + [providers[@"video"] count] + [providers[@"url"] count])) {
						callback(items, [[[url absoluteString] pathExtension] lowercaseString], nil);
					}
				}];
			}
		
		if([providers[@"txt"] count] > 0)
            for(NSItemProvider* provider in providers[@"txt"])
			{
				[provider loadItemForTypeIdentifier:TEXT_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                    NSString *text = (NSString *)item;
					[items addObject:text];

                    if(callback && [items count] == ([providers[@"txt"] count] + [providers[@"image"] count] + [providers[@"video"] count] + [providers[@"url"] count])) {
						callback(items, @"text/plain", nil);
					}
				}];
			}
        
        if([providers[@"url"] count] > 0)
            for(NSItemProvider* provider in providers[@"url"])
            {
                [provider loadItemForTypeIdentifier:TEXT_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                    [items addObject:(NSString *)item];

                    if(callback && [items count] == ([providers[@"txt"] count] + [providers[@"image"] count] + [providers[@"video"] count] + [providers[@"url"] count])) {
                        callback(items, @"text/url", nil);
                    }
                }];
            }
    }
    @catch (NSException *exception) {
        if(callback) {
            callback(nil, nil, exception);
        }
    }
}

@end
