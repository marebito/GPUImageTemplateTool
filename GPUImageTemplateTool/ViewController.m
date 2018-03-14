//
//  ViewController.m
//  GPUImageTemplateTool
//
//  Created by zll on 2018/3/14.
//  Copyright © 2018年 Godlike Studio. All rights reserved.
//

#import "ViewController.h"
#import "MGTemplateEngine.h"
#import "ICUTemplateMatcher.h"

#define WeakObj(o) try{}@finally{} __weak typeof(o) o##Weak = o;
#define StrongObj(o) autoreleasepool{} __strong typeof(o) o = o##Weak;

@interface ViewController ()
{
    NSString *templatePath_h;
    NSString *templatePath_m;
}
@property (weak) IBOutlet NSTextField *classNameTF;
@property (weak) IBOutlet NSComboBox *superClassCB;
@property (weak) IBOutlet NSView *canvasView;
@property (weak) IBOutlet NSTextField *canvasWidthTF;
@property (weak) IBOutlet NSTextField *canvasHeightTF;
@property (weak) IBOutlet NSButton *tex1SelBtn;
@property (weak) IBOutlet NSButton *tex2SelBtn;
@property (weak) IBOutlet NSButton *tex3SelBtn;
@property (weak) IBOutlet NSButton *videoSelBtn;
@property (weak) IBOutlet NSPathControl *tex1PC;
@property (weak) IBOutlet NSPathControl *tex2PC;
@property (weak) IBOutlet NSPathControl *tex3PC;
@property (weak) IBOutlet NSPathControl *mp4PC;
@property (weak) IBOutlet NSTextField *tex1DurationTF;
@property (weak) IBOutlet NSTextField *tex2DurationTF;
@property (weak) IBOutlet NSTextField *tex1StartTF;
@property (weak) IBOutlet NSTextField *tex2StartTF;
@property (weak) IBOutlet NSTextField *tex1EndTF;
@property (weak) IBOutlet NSTextField *tex2EndTF;
@property (weak) IBOutlet NSView *videoSettingView;

- (IBAction)generateAction:(id)sender;
- (IBAction)normalizedValueChanged:(id)sender;
- (IBAction)videoChecked:(id)sender;
- (IBAction)selectVideo:(id)sender;
- (IBAction)selectTexture:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (void)check:(void (^)(BOOL isValid))callback
{
    if ([_classNameTF.stringValue isEqualToString:@""])
    {
        [self showAlert:@[@"确定", @"取消"] message:@"类名不能为空!" informativeText:@"请填写类名" alertStyle:NSAlertStyleWarning isModal:NO callback:^(NSInteger btnIdx) {
            if (callback) callback(NO);
        }];
        return;
    }
}

- (void)showAlert:(NSArray *)btnTitles
          message:(NSString *)message
  informativeText:(NSString *)informativeText
       alertStyle:(NSAlertStyle)style
          isModal:(BOOL)isModal
         callback:(void (^)(NSInteger btnIdx))callback
{
    NSAlert *alert = [[NSAlert alloc] init];
    for (NSString *title in btnTitles)
    {
        [alert addButtonWithTitle:title];
    }
    [alert setMessageText:message];
    [alert setInformativeText:informativeText];
    [alert setAlertStyle:style];

    if (isModal)
    {
        NSModalResponse response = [alert runModal];
        if (callback) callback(response - 1000);
    }
    else
    {
        [alert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow] completionHandler:^(NSModalResponse returnCode) {
            if (callback) callback(returnCode - 1000);
        }];
    }
}

- (IBAction)generateAction:(id)sender {

    /*
     [self check:^(BOOL isValid) {
     if (isValid)
     {

     }
     else
     {

     return;
     }
     }];
     */

    // Set up template engine with your chosen matcher.
    MGTemplateEngine *engine = [MGTemplateEngine templateEngine];
    //    [engine setDelegate:self];
    [engine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:engine]];

    // Set up any needed global variables.
    // Global variables persist for the life of the engine, even when processing multiple templates.
    templatePath_h = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@Templater_h", _superClassCB.stringValue] ofType:@"txt"];
    templatePath_m = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@Templater_m", _superClassCB.stringValue] ofType:@"txt"];

    NSMutableArray *mArr = [NSMutableArray new];
    if ([_classNameTF.stringValue isEqualToString:@""])
    {
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:_classNameTF.stringValue, @"key", @"NSString", @"value", nil];
        [mArr addObject:dic];
    }
    /*
     if (![_param1TF.stringValue isEqualToString:@""]) {
     NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:_param1TF.stringValue, @"key", @"NSString", @"value", nil];
     [mArr addObject:dic];
     }
     if (![_param2TF.stringValue isEqualToString:@""]) {
     NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:_param2TF.stringValue, @"key", @"NSString", @"value", nil];
     [mArr addObject:dic];
     }
     if (![_param3TF.stringValue isEqualToString:@""]) {
     NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:_param3TF.stringValue, @"key", @"NSString", @"value", nil];
     [mArr addObject:dic];
     }
     if (![_param4TF.stringValue isEqualToString:@""]) {
     NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:_param4TF.stringValue, @"key", @"NSString", @"value", nil];
     [mArr addObject:dic];
     }
     if (![_param5TF.stringValue isEqualToString:@""]) {
     NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:_param5TF.stringValue, @"key", @"NSString", @"value", nil];
     [mArr addObject:dic];
     }
     if (![_param6TF.stringValue isEqualToString:@""]) {
     NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:_param6TF.stringValue, @"key", @"NSString", @"value", nil];
     [mArr addObject:dic];
     }
     */

    // Set up some variables for this specific template.
    NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
                               mArr, @"Param",
                               _classNameTF.stringValue, @"ClassName",
                               //                               _urlTF.stringValue, @"Url",
                               _superClassCB.stringValue, @"SuperClassName",
                               nil];

    // Process the template and display the results.
    NSString *resultH = [engine processTemplateInFileAtPath:templatePath_h withVariables:variables];
    NSString *resultM = [engine processTemplateInFileAtPath:templatePath_m withVariables:variables];

    //    NSLog(@"Processed template:\r%@", result);

    NSString *bundle = [[NSBundle mainBundle] resourcePath];
    NSString *deskTopLocation = [[bundle substringToIndex:[bundle rangeOfString:@"Library"].location] stringByAppendingFormat:@"Desktop"];
    NSString *filterTypeName = [self filterTypeName];
    NSString *pathH = [deskTopLocation stringByAppendingPathComponent:[NSString stringWithFormat:@"GPUImage%@%@.h", _classNameTF.stringValue, filterTypeName]];
    NSString *pathM = [deskTopLocation stringByAppendingPathComponent:[NSString stringWithFormat:@"GPUImage%@%@.m", _classNameTF.stringValue,filterTypeName]];
    NSError *errorH;
    NSError *errorM;
    BOOL isSuccessH = [resultH writeToFile:pathH atomically:YES encoding:NSUTF8StringEncoding error:&errorH];
    BOOL isSuccessM = [resultM writeToFile:pathM atomically:YES encoding:NSUTF8StringEncoding error:&errorM];

    if (isSuccessH && isSuccessM)
    {
        NSLog(@"success");
    }
    else
    {
        NSLog(@"fail");
        if (errorH)
        {
            NSLog(@"[头文件创建异常]:%@", errorH);
        }
        if (errorM)
        {
            NSLog(@"[实现文件创建异常]:%@", errorM);
        }
    }
}

- (NSString *)filterTypeName
{
    if ([_superClassCB.stringValue isEqualToString:@"GPUImageFilterGroup"]) {
        return @"FilterGroup";
    }
    return @"Filter";
}

- (void)selectFile:(void (^)(NSInteger, NSString *))callback panel:(NSOpenPanel *)panel result:(NSInteger)result {
    NSString *filePath = nil;
    if (result == NSModalResponseOK)
    {
        filePath = [panel.URLs.firstObject path];
    }
    if (callback) callback(result, filePath);
}

- (void)selectFile:(void (^)(NSInteger response, NSString *filePath))callback isPresent:(BOOL)isPresent
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    //是否可以创建文件夹
    panel.canCreateDirectories = YES;
    //是否可以选择文件夹
    panel.canChooseDirectories = YES;
    //是否可以选择文件
    panel.canChooseFiles = YES;

    //是否可以多选
    [panel setAllowsMultipleSelection:NO];

    __weak typeof(self) weakSelf = self;
    if (!isPresent)
    {
        //显示
        [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf selectFile:callback panel:panel result:result];
        }];
    }
    else
    {
        // 悬浮电脑主屏幕上
        [panel beginWithCompletionHandler:^(NSInteger result) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf selectFile:callback panel:panel result:result];
        }];
    }
}

- (IBAction)normalizedValueChanged:(id)sender
{
    self.canvasView.hidden = (((NSButton *)sender).state == NSControlStateValueOn);
}

- (IBAction)videoChecked:(id)sender
{
    self.videoSettingView.hidden = (((NSButton *)sender).state == NSControlStateValueOff);
}

- (void)updatePathControl:(NSPathControl *)pathCtl andSelectBtn:(NSButton *)btn filePath:(NSString *)filePath
{
    btn.hidden = YES;
    pathCtl.hidden = NO;
    pathCtl.URL = [NSURL URLWithString:filePath];
}

- (IBAction)selectVideo:(id)sender
{
    @WeakObj(self);
    [self selectFile:^(NSInteger response, NSString *filePath) {
        @StrongObj(self);
        if (response == NSModalResponseOK)
        {
            [self updatePathControl:self.mp4PC andSelectBtn:self.videoSelBtn filePath:filePath];
        }
    } isPresent:NO];
}

- (IBAction)selectTexture:(id)sender {
    @WeakObj(self);
    [self selectFile:^(NSInteger response, NSString *filePath) {
        @StrongObj(self);
        if (response == NSModalResponseOK)
        {
            switch (((NSButton *)sender).tag) {
                case 1:
                {
                    [self updatePathControl:self.tex1PC andSelectBtn:self.tex1SelBtn filePath:filePath];
                }
                    break;
                case 2:
                {
                    [self updatePathControl:self.tex2PC andSelectBtn:self.tex2SelBtn filePath:filePath];
                }
                    break;
                case 3:
                {
                    [self updatePathControl:self.tex3PC andSelectBtn:self.tex3SelBtn filePath:filePath];
                }
                    break;
                default:
                    break;
            }
        }
    } isPresent:NO];
}

@end
