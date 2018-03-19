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
#import "TexturePopoverVC.h"

#define WeakObj(o) try{}@finally{} __weak typeof(o) o##Weak = o;
#define StrongObj(o) autoreleasepool{} __strong typeof(o) o = o##Weak;

@interface ViewController () <NSPopoverDelegate>
{
    NSString *templatePath_h; // 模板头文件
    NSString *templatePath_m; // 模板实现文件
}
@property (weak) IBOutlet NSTextField *classNameTF;    // 类名
@property (weak) IBOutlet NSComboBox *superClassCB;    // 父类选择框
@property (weak) IBOutlet NSView *canvasView;          // 画布设置视图
@property (weak) IBOutlet NSTextField *canvasWidthTF;  // 画布宽输入框
@property (weak) IBOutlet NSTextField *canvasHeightTF; // 画布高输入框
@property (weak) IBOutlet NSButton *tex1SelBtn;        // 纹理1选择按钮
@property (weak) IBOutlet NSButton *tex2SelBtn;        // 纹理2选择按钮
@property (weak) IBOutlet NSButton *tex3SelBtn;        // 纹理3选择按钮
@property (weak) IBOutlet NSButton *platformSelBtn;       // 视频选择按钮
@property (weak) IBOutlet NSButton *videoSelBtn;       // 视频选择按钮
@property (weak) IBOutlet NSButton *shaderSelBtn;      // 是否自动产生shader
@property (weak) IBOutlet NSPathControl *tex1PC;       // 纹理1路径显示
@property (weak) IBOutlet NSPathControl *tex2PC;       // 纹理2路径显示
@property (weak) IBOutlet NSPathControl *tex3PC;       // 纹理3路径显示
@property (weak) IBOutlet NSTextField *tex1NameTF;     // 纹理1名称输入框
@property (weak) IBOutlet NSTextField *tex2NameTF;     // 纹理2名称输入框
@property (weak) IBOutlet NSTextField *tex3NameTF;     // 纹理3名称输入框
@property (weak) IBOutlet NSTextField *videoInputTF;   // 纹理3名称输入框
@property (weak) IBOutlet NSPathControl *mp4PC;        // mp4路径
@property (weak) IBOutlet NSTextField *tex1DurationTF; // 纹理1时长输入框
@property (weak) IBOutlet NSTextField *tex2DurationTF; // 纹理2时长输入框
@property (weak) IBOutlet NSTextField *tex3DurationTF; // 纹理3时长输入框
@property (weak) IBOutlet NSTextField *tex1StartTF;
@property (weak) IBOutlet NSTextField *tex2StartTF;
@property (weak) IBOutlet NSTextField *tex3StartTF;
@property (weak) IBOutlet NSTextField *tex1EndTF;
@property (weak) IBOutlet NSTextField *tex2EndTF;
@property (weak) IBOutlet NSTextField *tex3EndTF;
@property (weak) IBOutlet NSView *videoSettingView;

@property (nonatomic, strong) TexturePopoverVC *popoverVC;  // 弹出窗口
@property (nonatomic, strong) NSPopover *texturePopover;    // 纹理悬浮窗
@property (strong) NSWindow *detachedWindow;                // 附加窗口
@property (strong) NSPanel *detachedHUDWindow;              // 附加显示面板

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

    NSRect frame = self.popoverVC.view.bounds;
    NSUInteger styleMask = NSWindowStyleMaskTitled + NSWindowStyleMaskClosable;
    NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
    _detachedWindow = [[NSWindow alloc] initWithContentRect:rect styleMask:styleMask backing:NSBackingStoreBuffered defer:YES];
    self.detachedWindow.contentViewController = self.popoverVC;
    self.detachedWindow.releasedWhenClosed = NO;

    styleMask = NSWindowStyleMaskTitled + NSWindowStyleMaskClosable + NSWindowStyleMaskHUDWindow + NSWindowStyleMaskUtilityWindow;
    _detachedHUDWindow = [[NSPanel alloc] initWithContentRect:rect styleMask:styleMask backing:NSBackingStoreBuffered defer:YES];
    self.detachedHUDWindow.contentViewController = self.popoverVC;
    self.detachedHUDWindow.releasedWhenClosed = NO;
}

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
}

- (NSPopover *)texturePopover
{
    if (!_texturePopover) {
        _texturePopover = [[NSPopover alloc] init];
        _popoverVC = [self.storyboard instantiateControllerWithIdentifier:@"TexturePopoverVC"];
        _texturePopover.contentViewController = _popoverVC;
        _texturePopover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
        _texturePopover.animates = YES;
        _texturePopover.behavior = NSPopoverBehaviorTransient;
        _texturePopover.delegate = self;
    }
    return _texturePopover;
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

    NSMutableArray *textureAttributes = [NSMutableArray new];
    BOOL iosPlatform = (_platformSelBtn.state = NSControlStateValueOn);
    BOOL enableFragmentShader = (_shaderSelBtn.state == NSControlStateValueOn);

    if (![_tex1NameTF.stringValue isEqualToString:@""])
    {
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:_tex1NameTF.stringValue, @"attr", @"GPUImagePicture", @"type", iosPlatform?[_tex1PC.stringValue lastPathComponent]: _tex1PC.stringValue, @"resource", nil];
        [textureAttributes addObject:dic];
    }
    if (![_tex2NameTF.stringValue isEqualToString:@""])
    {
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:_tex2NameTF.stringValue, @"attr", @"GPUImagePicture", @"type",  iosPlatform?[_tex2PC.stringValue lastPathComponent]:_tex2PC.stringValue, @"resource", nil];
        [textureAttributes addObject:dic];
    }
    if (![_tex3NameTF.stringValue isEqualToString:@""])
    {
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:_tex3NameTF.stringValue, @"attr", @"GPUImagePicture", @"type", iosPlatform? [_tex3PC.stringValue lastPathComponent]:_tex3PC.stringValue, @"resource", nil];
        [textureAttributes addObject:dic];
    }
    if (![_videoInputTF.stringValue isEqualToString:@""])
    {
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:_videoInputTF.stringValue, @"attr", @"GPUImageMovie", @"type", iosPlatform?[_mp4PC.stringValue lastPathComponent]:_mp4PC.stringValue, @"resource", nil];
        [textureAttributes addObject:dic];
    }
    // Set up some variables for this specific template.
    NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
                               _classNameTF.stringValue, @"ClassName",
                               _superClassCB.stringValue, @"SuperClassName",
                               textureAttributes, @"TextureAttributes",
                               enableFragmentShader, @"ShaderEnabled",
                               iosPlatform, @"iOSPlatform",
                               nil];

    // Process the template and display the results.
    NSString *resultH = [engine processTemplateInFileAtPath:templatePath_h withVariables:variables];
    NSString *resultM = [engine processTemplateInFileAtPath:templatePath_m withVariables:variables];

    //    NSLog(@"Processed template:\r%@", result);

    NSString *bundle = [[NSBundle mainBundle] resourcePath];
    NSString *filtersLocation = [[bundle substringToIndex:[bundle rangeOfString:@"Library"].location] stringByAppendingPathComponent:@"Desktop/GenerateFilters"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filtersLocation])
    {
        NSError * error = nil;
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:filtersLocation
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:&error];
        if (!success || error) {
            NSLog(@"[创建文件夹失败]! %@", error);
            return;
        }
    }
    NSString *filterTypeName = [self filterTypeName];
    NSString *pathH = [filtersLocation stringByAppendingPathComponent:[NSString stringWithFormat:@"GPUImage%@%@.h", _classNameTF.stringValue, filterTypeName]];
    NSString *pathM = [filtersLocation stringByAppendingPathComponent:[NSString stringWithFormat:@"GPUImage%@%@.m", _classNameTF.stringValue,filterTypeName]];
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

- (void)updateWindowSize
{
    NSRect windowFrame = [self.view.window frame];
    // 加上SubView高度和宽度的变化值
    windowFrame.size.height += 20.0;
    windowFrame.size.width += 0.0;
    // 为了保持窗口左上角位置不变，需要重设窗口框的绘制起点的y值
    // 之所以用 -= 是因为Cocoa的绘图起点是左下角
    // 起点的x值无需改变。
    windowFrame.origin.y -= 20.0;
    // 改变窗口大小，使用动画
    [self.view.window setFrame:windowFrame display:YES animate:YES];
}

- (IBAction)videoChecked:(id)sender
{
    //    [self updateWindowSize];
    self.videoSettingView.hidden = (((NSButton *)sender).state == NSControlStateValueOff);
}

- (void)updatePathControl:(NSPathControl *)pathCtl
                selectBtn:(NSButton *)btn
                 filePath:(NSString *)filePath
{
    btn.hidden = YES;
    pathCtl.hidden = NO;
    pathCtl.URL = [NSURL fileURLWithPath:filePath];
}

- (IBAction)selectVideo:(id)sender
{
    @WeakObj(self);
    [self selectFile:^(NSInteger response, NSString *filePath) {
        @StrongObj(self);
        if (response == NSModalResponseOK)
        {
            [self updatePathControl:self.mp4PC selectBtn:self.videoSelBtn filePath:filePath];
        }
    } isPresent:NO];
}

- (IBAction)selectTexture:(id)sender
{
    @WeakObj(self);
    [self selectFile:^(NSInteger response, NSString *filePath) {
        @StrongObj(self);
        if (response == NSModalResponseOK)
        {
            switch (((NSButton *)sender).tag) {
                case 1:
                {
                    [self updatePathControl:self.tex1PC selectBtn:self.tex1SelBtn filePath:filePath];
                }
                    break;
                case 2:
                {
                    [self updatePathControl:self.tex2PC selectBtn:self.tex2SelBtn filePath:filePath];
                }
                    break;
                case 3:
                {
                    [self updatePathControl:self.tex3PC selectBtn:self.tex3SelBtn filePath:filePath];
                }
                    break;
                default:
                    break;
            }
        }
    } isPresent:NO];
}
- (IBAction)showPopoverAction:(id)sender
{
    [self showPopoverAction:sender popoverPosition:NSRectEdgeMaxX];
}

- (void)showPopoverAction:(id)sender popoverPosition:(NSRectEdge)prefEdge
{
    if (self.detachedWindow.visible == YES)
    {
        [self.detachedWindow close];
    }

    if (self.detachedHUDWindow.visible)
    {
        [self.detachedHUDWindow makeKeyAndOrderFront:self];
        return;
    }

    [self.texturePopover showRelativeToRect:((NSControl *)sender).bounds ofView:sender preferredEdge:prefEdge];
}

#pragma mark -
#pragma mark NSPopoverDelegate Methods
// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverWillShowNotification notification is sent.
// This method will also be invoked on the popover.
// -------------------------------------------------------------------------------
- (void)popoverWillShow:(NSNotification *)notification
{
    NSPopover *popover = notification.object;
    if (popover != nil)
    {
        //... operate on that popover
    }
}

// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverDidShowNotification notification is sent.
// This method will also be invoked on the popover.
// -------------------------------------------------------------------------------
- (void)popoverDidShow:(NSNotification *)notification
{
    // add new code here after the popover has been shown
}

// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverWillCloseNotification notification is sent.
// This method will also be invoked on the popover.
// -------------------------------------------------------------------------------
- (void)popoverWillClose:(NSNotification *)notification
{
    NSString *closeReason = [notification.userInfo valueForKey:NSPopoverCloseReasonKey];
    if (closeReason)
    {
        // closeReason can be:
        //      NSPopoverCloseReasonStandard
        //      NSPopoverCloseReasonDetachToWindow
        //
        // add new code here if you want to respond "before" the popover closes
        //
    }
}

// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverDidCloseNotification notification is sent.
// This method will also be invoked on the popover.
// -------------------------------------------------------------------------------
- (void)popoverDidClose:(NSNotification *)notification
{
    NSString *closeReason = [notification.userInfo valueForKey:NSPopoverCloseReasonKey];
    if (closeReason)
    {
        // closeReason can be:
        //      NSPopoverCloseReasonStandard
        //      NSPopoverCloseReasonDetachToWindow
        //
        // add new code here if you want to respond "after" the popover closes
        //
    }

    // release our popover since it closed
    _texturePopover = nil;
}

// -------------------------------------------------------------------------------
// Invoked on the delegate to give permission to detach popover as a separate window.
// -------------------------------------------------------------------------------
- (BOOL)popoverShouldDetach:(NSPopover *)popover
{
    return YES;
}

// -------------------------------------------------------------------------------
// Invoked on the delegate to when the popover was detached.
// Note: Invoked only if AppKit provides the window for this popover.
// -------------------------------------------------------------------------------
- (void)popoverDidDetach:(NSPopover *)popover
{
    NSLog(@"popoverDidDetach");
}

// -------------------------------------------------------------------------------
// Invoked on the delegate asked for the detachable window for the popover.
// -------------------------------------------------------------------------------
- (NSWindow *)detachableWindowForPopover:(NSPopover *)popover
{
    return nil;
}

#pragma mark - NSApplicationDelegate Methods
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
