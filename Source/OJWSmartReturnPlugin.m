//
//  OJWSmartReturnPlugin.m
//  OJWSmartReturn
//
// Created by Joseph Wardell on 2/4/12
// with thanks to Ole Zorn for a great XCode plugin example in OMColorSense
//
//

#import "OJWSmartReturnPlugin.h"


@implementation OJWSmartReturnPlugin

#pragma mark - Plugin Initialization

+ (void)pluginDidLoad:(NSBundle *)plugin
{
	static id sharedPlugin = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedPlugin = [[self alloc] init];
	});
}

- (id)init
{
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
	}
	return self;
}

- (IBAction)insertDate:(id)sender;
{
    NSTextView* textView = nil;
    NSResponder *firstResponder = [[NSApp keyWindow] firstResponder];
    if ([firstResponder isKindOfClass:NSClassFromString(@"DVTSourceTextView")] && [firstResponder isKindOfClass:[NSTextView class]]) {
        textView = (NSTextView *)firstResponder;
    }
    if (nil == textView)
    {
        NSBeep();
        return;
    }


	[textView.undoManager beginUndoGrouping];
    
    [textView insertText:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle] replacementRange:textView.selectedRange];
    
	[textView.undoManager endUndoGrouping];
}

- (IBAction)insertReturnAtEndOfLine:(id)sender;
{
    [self insertRecturnWithPrefix:@""];
}

- (IBAction)insertSemicoloAtEndOfLine:(id)sender;
{
    [self insertRecturnWithPrefix:@";"];
}


- (void)insertRecturnWithPrefix:(NSString*)inPrefix;
{
    NSTextView* textView = nil;
    NSResponder *firstResponder = [[NSApp keyWindow] firstResponder];
    if ([firstResponder isKindOfClass:NSClassFromString(@"DVTSourceTextView")] && [firstResponder isKindOfClass:[NSTextView class]])
        textView = (NSTextView *)firstResponder;
    if (nil == textView)
    {
        NSBeep();
        return;
    }
    
    NSString* suffixToAppend = @"\n";
    if (inPrefix.length)
        suffixToAppend = [inPrefix stringByAppendingString:suffixToAppend];

    
    @try {
        NSRange rangeToInsert = NSMakeRange(textView.string.length, 0);
//        NSLog(@"rangetoinsert: %@", NSStringFromRange(rangeToInsert));
        
        
        NSRange nextNewLineRange = [textView.string rangeOfString:@"\n" options:0 range:NSMakeRange(textView.selectedRange.location, textView.string.length - textView.selectedRange.location)];
        
//        NSLog(@"nextNewLineRange: %@", NSStringFromRange(nextNewLineRange));
        
        NSRange rangeToSearch = NSMakeRange(0, nextNewLineRange.location);
        if (nextNewLineRange.location == NSNotFound)
            rangeToSearch.length = textView.string.length;
        
        suffixToAppend = @"\n";

        NSError* error;
        NSRegularExpression *previousNewlinePattern = [NSRegularExpression regularExpressionWithPattern:@"(^([ |\\t]*))|(\\n([ |\\t]*))" options:NSRegularExpressionCaseInsensitive error:&error];
        if (nil == previousNewlinePattern)
            NSLog(@"XCodeSmartReturn: Error creating regular expression \\n([ |\\t]*): %@", error.localizedDescription);
        
        NSArray* newlineMatches = [previousNewlinePattern matchesInString:textView.string options:0 range:rangeToSearch];
//        NSLog(@"matches: %li", (unsigned long)newlineMatches.count);
        
        //    NSUInteger numberOfMatches = [previousNewlinePattern numberOfMatchesInString:textView.string options:0 range:NSMakeRange(0, textView.selectedRange.location-1)];
        if (newlineMatches.count)
        {
            NSTextCheckingResult* result = [newlineMatches lastObject];
            if (nil != result)
            {
//                NSLog(@"Found it!");
                NSRange newLineToInsertRange = result.range;
//                NSLog(@"range: %@", NSStringFromRange(newLineToInsertRange));
                
                  
                suffixToAppend = [textView.string substringWithRange:newLineToInsertRange];
            }
        }
        
        // it's possible the new line disappeared in the above check
        if (![suffixToAppend hasPrefix:@"\n"])
            suffixToAppend = [@"\n" stringByAppendingString:suffixToAppend];

        if (inPrefix.length)
            suffixToAppend = [inPrefix stringByAppendingString:suffixToAppend];

//        NSLog(@"suffixToAppend: '%@'", suffixToAppend);
        
        
        if (nextNewLineRange.location == NSNotFound)
        {
            [textView.undoManager beginUndoGrouping];
            [textView replaceCharactersInRange:NSMakeRange(textView.string.length, 0) withString:suffixToAppend];
            [textView setSelectedRange:NSMakeRange(textView.string.length, 0)];
            [textView scrollRangeToVisible:NSMakeRange(textView.string.length, 0)];
            
            [textView.undoManager endUndoGrouping];
        }
        else
        {
            rangeToInsert = nextNewLineRange;
            rangeToInsert.length = 0;
            
            
            if (rangeToInsert.location > textView.string.length)
            {
//                NSLog(@"Bad insertion range!");
                return;
            }
            NSRange rangeToSelect = NSMakeRange(rangeToInsert.location + suffixToAppend.length, 0);
            if (rangeToSelect.location > textView.string.length+suffixToAppend.length)
            {
//                NSLog(@"Bad selection range!");
                return;
            }
            
            [textView.undoManager beginUndoGrouping];
            
            [textView insertText:suffixToAppend replacementRange:rangeToInsert];
            [textView setSelectedRange:rangeToSelect];
            [textView scrollRangeToVisible:rangeToSelect];
            
            [textView.undoManager endUndoGrouping];
        }

    }
    @catch (NSException *exception) {
        NSLog(@"XCode Smart Return: exception caught: %@", exception.description);

    }
}


- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
	if (editMenuItem) {
		[[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];
		
        NSMenuItem* insReturnMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Insert Return at end of Line" action:@selector(insertReturnAtEndOfLine:) keyEquivalent:@"\n"] autorelease];
        [insReturnMenuItem setTarget:self];
        [insReturnMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
        [[editMenuItem submenu] addItem:insReturnMenuItem];

        NSMenuItem* insSCMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Insert ; at end of Line" action:@selector(insertSemicoloAtEndOfLine:) keyEquivalent:@";"] autorelease];
        [insSCMenuItem setTarget:self];
        [insSCMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
        [[editMenuItem submenu] addItem:insSCMenuItem];

#if INCLUDEDATEMENUITEM
		[[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];

        NSMenuItem* insDateMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Insert Date" action:@selector(insertDate:) keyEquivalent:@"D"] autorelease];
        [insDateMenuItem setTarget:self];
        [insDateMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask | NSControlKeyMask];
        [[editMenuItem submenu] addItem:insDateMenuItem];
#endif
    }
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (([menuItem action] == @selector(insertReturnAtEndOfLine:)) ||
        ([menuItem action] == @selector(insertSemicoloAtEndOfLine:)) ||
        ([menuItem action] == @selector(insertDate:)))
    {

		NSResponder *firstResponder = [[NSApp keyWindow] firstResponder];
		return ([firstResponder isKindOfClass:NSClassFromString(@"DVTSourceTextView")] && [firstResponder isKindOfClass:[NSTextView class]]);
    }
    return YES;
}



#pragma mark -

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

@end
