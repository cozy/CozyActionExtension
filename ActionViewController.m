//
//  ActionViewController.m
//  CozyActionExtension
//
//  Created by Olivier on 17/08/2017.
//
//


// TODO: use framework or common code w/ app

#import "ActionViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>


@interface FileCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *ivIcon;
@property (weak, nonatomic) IBOutlet UILabel *lbName;
@end


@interface ActionViewController () {
    NSMutableArray<NSURL *> * mFileURLs;
    NSUInteger mTotalSize;
}
@property(strong,nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *tvMain;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btCancel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btUpload;
@property (weak, nonatomic) IBOutlet UIView *uvAlpha;
@property (weak, nonatomic) IBOutlet UIView *uvUploading;
@property (weak, nonatomic) IBOutlet UILabel *lbUploading;
@property (weak, nonatomic) IBOutlet UILabel *lbFileName;
@property (weak, nonatomic) IBOutlet UILabel *lbPercent;
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
    
    
    mFileURLs = [NSMutableArray new];
    
    // TODO: write moar elegant code :p
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeFileURL]) {
                
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeFileURL options:kNilOptions completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                    if(error == nil) {
                        NSURL * url = (NSURL *)item;
                        [mFileURLs addObject:url];
                    }
                }];
                
            }
            else if([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                    if(error == nil) {
                        NSURL * url = (NSURL *)item;
                        [mFileURLs addObject:url];
                    }
                }];
            }
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
    
    NSString * base_url = @"https://zlot.mycozy.cloud";
    
    // TODO: create queue instead of several // reqs ?
    mTotalSize = 0;
    for(NSURL * url in mFileURLs) {
        NSDictionary * attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[url relativePath] error:nil];
        mTotalSize += [[attrs objectForKey:NSFileSize] unsignedIntegerValue];
    }
    
    
    for(NSURL * url in mFileURLs) {
       NSString * file_name = [url lastPathComponent];
        NSString * url_str = [NSString stringWithFormat:@"%@/files/io.cozy.files.root-dir?Type=file&Name=%@&Tags=file&Executable=false", base_url, file_name];
        
        
        // TODO: use background ?
        NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession * session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url_str]];
        [request setHTTPMethod: @"POST"];
        
        [request setValue:[self getMimeTypeFromPath:file_name] forHTTPHeaderField:@"Content-Type"];
        [request setValue:token forHTTPHeaderField:@"Authorization"];
        
        NSURLSessionUploadTask * task = [session uploadTaskWithRequest:request fromFile:url];
        [task resume];
    }
    
    if([mFileURLs count] > 1) {
        [[self lbFileName] setText:[NSString stringWithFormat:@"%ld files", [mFileURLs count]]];
    }
    else {
        NSURL * url = [mFileURLs objectAtIndex:0];
        [[self lbFileName] setText:[url lastPathComponent]];
    }
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
    NSLog(@"didSendBodyData: send %lld / %lld", totalBytesSent, (int64_t)mTotalSize);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        float val = (float)((float)totalBytesSent / (float)mTotalSize);
        [[self pvProgress] setProgress:val];
        NSLog(@"%f", val);
        val *= 100.0;
        NSLog(@"%d", (int)val);
        [[self lbPercent] setText:[NSString stringWithFormat:@"%d %%", (int)val]];
    });
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
    return [mFileURLs count];
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
    
    NSURL * url = [mFileURLs objectAtIndex:[indexPath row]];
    [[cell lbName] setText:[url lastPathComponent]];
    
    // try loading image lol
    UIImage * img = [UIImage imageWithContentsOfFile:[url relativePath]];
    if(img) {
        [[cell ivIcon] setImage:img];
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
