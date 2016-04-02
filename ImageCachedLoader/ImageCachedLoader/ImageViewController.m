//
//  ImageViewController.m
//  ImageCachedLoader
//
//  Created by Ikuo Kudo on 12/06/27.
//  Copyright (c) 2012年 . All rights reserved.
//

#import "ImageViewController.h"
#import "ImageCacheController.h"

const float cellImageWidth = 120;
const float cellImageHeight = 80;
const float cellHeight = cellImageHeight + 20;

@interface ImageViewController ()

@property (nonatomic, strong) UIWebView* webView;
@property (nonatomic, strong) NSMutableArray* imageUrlList;
@property (nonatomic, strong) ImageCacheController* cacheController;
@end

@implementation ImageViewController
@synthesize webView, imageUrlList;
@synthesize cacheController;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
        self.webView = [[UIWebView alloc] initWithFrame: CGRectZero];
        self.webView.delegate = self;
        
        self.cacheController = [[ImageCacheController alloc] init];
        [self.cacheController loadDefaultImage:  @"loading.png"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSURL* url = [NSURL URLWithString: @"http://www.yahoo.co.jp"];
    [self.webView loadRequest: [NSURLRequest requestWithURL: url]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.imageUrlList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = [indexPath row];
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: CellIdentifier];
    }
    
    if(self.imageUrlList && row < [self.imageUrlList count]) {
        NSString* url = (NSString*) [imageUrlList objectAtIndex: row];
        UIImage* image = [cacheController loadImageWithURLString: url];
        if(!image) image = cacheController.defaultImage;
    
        CGSize size = image.size;
        float rate;
        float cellSize = 40;
        if(size.width > size.height) {
            //横長
            rate = cellSize / size.width;
        }
        else {
            //縦長
            rate = cellSize / size.height;
        }
        
        size.width *= rate;
        size.height *= rate;
        
        CGInterpolationQuality quality = kCGInterpolationHigh;
        UIImage* trimmedImage;
        UIGraphicsBeginImageContext(CGSizeMake(size.width, size.height));
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetInterpolationQuality(context, quality);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        trimmedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        cell.imageView.image = trimmedImage;
        cell.textLabel.text = url;
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}



- (void) webViewDidFinishLoad:(UIWebView *) aWebView
{
    if(self.imageUrlList) {
        [self.imageUrlList removeAllObjects];
    }
    else {
        self.imageUrlList = [NSMutableArray arrayWithCapacity: 0];  
    }
                                
    NSString* num = [aWebView stringByEvaluatingJavaScriptFromString: @"document.getElementsByTagName('img').length"];
    
    if(!num) return;
    int size = [num intValue];
    for(int i = 0; i < size; i++) {
        NSString* js =[NSString stringWithFormat: @"var c = document.getElementsByTagName('img');"    
                                                    "c[%d].getAttribute('src');", i];
        NSString* url = [aWebView stringByEvaluatingJavaScriptFromString: js];
        [self.imageUrlList addObject:  url];
        [cacheController loadImageWithURLString: url];
    }
    
    for(int i = 0; i < [self.imageUrlList count]; i++) 
        NSLog(@"url= %@", [self.imageUrlList objectAtIndex: i]);

    [self.tableView reloadData];
}


@end
