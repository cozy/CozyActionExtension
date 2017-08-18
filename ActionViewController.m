//
//  ActionViewController.m
//  CozyActionExtension
//
//  Created by Olivier on 17/08/2017.
//
//

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>


@interface FileCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *ivIcon;
@property (weak, nonatomic) IBOutlet UILabel *lbName;
@end


@interface ActionViewController () {
    NSURL * mFileURL;
}
@property(strong,nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *tvMain;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btCancel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btUpload;
@property (weak, nonatomic) IBOutlet UIView *uvAlpha;
@property (weak, nonatomic) IBOutlet UIView *uvUploading;
@property (weak, nonatomic) IBOutlet UILabel *lbUploading;
@property (weak, nonatomic) IBOutlet UILabel *lbFileName;
@property (weak, nonatomic) IBOutlet UIProgressView *pvProgress;
@end


@implementation FileCell
@end


@implementation ActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self showProgress:NO];
    [[[self uvUploading] layer] setCornerRadius:4.0];
    [[[self uvUploading] layer] setMasksToBounds:YES];
    
    [[self tvMain] setDelegate:self];
    [[self tvMain] setDataSource:self];
    
    
    // Get the item[s] we're handling from the extension context.
    
    // For example, look for an image and place it into an image view.
    // Replace this with something appropriate for the type[s] your extension supports.
    BOOL imageFound = NO;
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeFileURL]) {
                
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeFileURL options:kNilOptions completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                    if(error == nil) {
                        
                        mFileURL = (NSURL *)item;
                        
                        NSDictionary * attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[mFileURL relativePath] error:&error];
                        NSLog(@"%@", attrs);
                        
                        
//                        UIWebView * webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
//                        NSString *urlString = @"cozydrive://test";
//                        NSString * content = [NSString stringWithFormat : @"<head><meta http-equiv='refresh' content='0; URL=%@'></head>", urlString];
//                        [webView loadHTMLString:content baseURL:nil];
//                        [self.view addSubview:webView];
//                        [webView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:2.0];

                        
//                        [[self extensionContext] openURL:[NSURL URLWithString:url_str] completionHandler:^(BOOL success) {
//                            NSLog(@"open url : %d", success);
//                        }];
                    }
                }];
                
            }
            
            
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                // This is an image. We'll load it, then place it in our image view.
                __weak UIImageView *imageView = self.imageView;
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(UIImage *image, NSError *error) {
                    if(image) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [imageView setImage:image];
                        }];
                    }
                }];
                
                imageFound = YES;
                break;
            }
        }
        
        if (imageFound) {
            // We only handle one image, so stop looking for more.
            break;
        }
    }
}


- (void)showProgress:(BOOL)aShow {
    [[self uvUploading] setUserInteractionEnabled:aShow];
    [[self uvAlpha] setUserInteractionEnabled:aShow];
    
    [[self uvUploading] setAlpha:aShow ? 1.0 : 0.0];
    [[self uvAlpha] setAlpha:aShow ? 0.3 : 0.0];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onCancelClicked:(id)sender {
    // Return any edited content to the host app.
    // This template doesn't do anything, so we just echo the passed in items.
    [self.extensionContext completeRequestReturningItems:self.extensionContext.inputItems completionHandler:nil];
}


- (IBAction)onUploadClicked:(id)sender {
    
    // TODO: get token + base url from shared data
    
    NSString * token = [NSString stringWithFormat:@"Bearer %@", @"eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhY2Nlc3MiLCJpYXQiOjE1MDI0NjU3ODAsImlzcyI6Inpsb3QubXljb3p5LmNsb3VkIiwic3ViIjoiYWI4MDY0Zjc4OTE4OWY5ODE4YjVjZTUxMzBkZWUxODMiLCJzY29wZSI6ImlvLmNvenkuZmlsZXMgaW8uY296eS5jb250YWN0cyBpby5jb3p5LmpvYnM6UE9TVDpzZW5kbWFpbDp3b3JrZXIifQ.A3p_Qdn1Ky4fCmxyINgknJ0_mIUvPbyoBZu3-XMmdLlV5spcXV_v9b203ytSqGrUDBNmA_w40rUBJC0Xo_NyEw"];
    
    NSString * file_name = [mFileURL lastPathComponent];
    NSString * url_str = [NSString stringWithFormat:@"%@/files/io.cozy.files.root-dir?Type=file&Name=%@&Tags=file&Executable=false", @"https://zlot.mycozy.cloud", file_name];
    
    
    NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url_str]];
    [request setHTTPMethod: @"POST"];
    
    [request setValue:[self getMimeTypeFromPath:file_name] forHTTPHeaderField:@"Content-Type"];
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionUploadTask * task = [session uploadTaskWithRequest:request fromFile:mFileURL];
    [task resume];

    
    [[self lbFileName] setText:file_name];
    [[self pvProgress] setProgress:0.0];
    [self showProgress:YES];
}


- (NSString *)getMimeTypeFromPath:(NSString *)fullPath {
    NSString * mimeType = @"application/octet-stream";
    if (fullPath) {
        CFStringRef typeId = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[fullPath pathExtension], NULL);
        if (typeId) {
            mimeType = (__bridge_transfer NSString*)UTTypeCopyPreferredTagWithClass(typeId, kUTTagClassMIMEType);
            if (!mimeType) {
                // special case for m4a
                if ([(__bridge NSString*)typeId rangeOfString : @"m4a-audio"].location != NSNotFound) {
                    mimeType = @"audio/mp4";
                } else if ([[fullPath pathExtension] rangeOfString:@"wav"].location != NSNotFound) {
                    mimeType = @"audio/wav";
                } else if ([[fullPath pathExtension] rangeOfString:@"css"].location != NSNotFound) {
                    mimeType = @"text/css";
                } else {
                    mimeType = @"application/octet-stream";
                }
            }
            CFRelease(typeId);
        }
    }
    return mimeType;
}



// ====================================================================================================================
#pragma mark - NSURLSessionDelegate
// ====================================================================================================================
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    NSLog(@"didReceiveChallenge");
    NSURLCredential * credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
}


- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"URLSessionDidFinishEventsForBackgroundURLSession");
}


// ====================================================================================================================
#pragma mark - NSURLSessionTaskDelegate
// ====================================================================================================================
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    NSLog(@"didSendBodyData: send %lld / %lld", totalBytesSent, totalBytesExpectedToSend);
    [[self pvProgress] setProgress:(double)totalBytesExpectedToSend / (double)totalBytesSent];
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSHTTPURLResponse * response = (NSHTTPURLResponse *)[task response];
    long status = (long)[response statusCode];
    
    // cleanup
    if(error && status >= 400) {
        NSLog(@"Error: %@", error);
        
    } else {
        NSLog(@"--- UPLOAD OK ---");
        NSLog(@"%@", response);
    }
    
    [self showProgress:NO];
    [self onCancelClicked:nil];
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(nonnull void (^)(NSInputStream * _Nullable))completionHandler {
    NSLog(@"needNewBodyStream");
}


// ====================================================================================================================
#pragma mark - UITableViewController
// ====================================================================================================================
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"File";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString * cell_id = @"idFileCell";
    FileCell * cell = (FileCell *)[tableView dequeueReusableCellWithIdentifier:cell_id];
    if(cell == nil) {
        cell = [[FileCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:cell_id];
    }
    [[cell lbName] setText:[mFileURL lastPathComponent]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}






@end
