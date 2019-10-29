#import "ReactNativeShareExtension.h"
#import "React/RCTRootView.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define URL_IDENTIFIER @"public.url"
#define IMAGE_IDENTIFIER @"public.image"
#define TEXT_IDENTIFIER (NSString *)kUTTypePlainText

NSExtensionContext* extensionContext;

@implementation ReactNativeShareExtension {
    NSTimer *autoTimer;
    NSString* type;
    NSString* value;
}

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
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
    [self extractDataFromContext: extensionContext withCallback:^(NSMutableArray* media, NSString* text, NSException* err) {
        if(err)
            reject(@"error", err.description, nil);
        else
		{
			if(text == nil)
				text = @"";

            resolve(@{
                      @"media": media,
					  @"text": text
                      });
        }
    }];
}

- (void)extractDataFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSMutableArray *media, NSString* text, NSException *exception))callback {
    
    @try {
        NSExtensionItem *item 			= [context.inputItems firstObject];
        NSArray *attachments 			= item.attachments;
		__block int amount				= 0;
		__block int success				= 0;
		__block NSMutableArray *media	= [[NSMutableArray alloc] init];
		__block NSString *text			= nil;

        [attachments enumerateObjectsUsingBlock:^(NSItemProvider *provider, NSUInteger idx, BOOL *stop) {
			amount++;
			
			if ([provider hasItemConformingToTypeIdentifier:TEXT_IDENTIFIER])
			{
				[provider loadItemForTypeIdentifier:TEXT_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
					text = (NSString *)item;
					
					success++;
					
					if(success == amount)
						callback(media, text, nil);
				}];
				
				*stop = YES;
			}
			else if ([provider hasItemConformingToTypeIdentifier:URL_IDENTIFIER])
			{
				[provider loadItemForTypeIdentifier:URL_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
					text = [(NSURL *)item absoluteString];
					
					success++;
					
					if(success == amount)
						callback(media, text, nil);
				}];
				
				*stop = YES;
			}
			else if ([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER])
			{
				[provider loadItemForTypeIdentifier:IMAGE_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
					NSURL *url = (NSURL *)item;
					
					[media addObject:[url absoluteString]];
					
					success++;
					
					if(success == amount)
						callback(media, text, nil);
				}];
			}
			else
				amount--;
        }];
    }
    @catch (NSException *exception)
	{
        if(callback)
			callback(nil, nil, exception);
    }
}

@end
