//
//  GRFSummaryController.m
//  Experiment
//
//  Window with summary information trial events.
//
//  Copyright (c) 2006. All rights reserved.
//

#define NoGlobals

// enum {kEOTCorrect = 0, kEOTWrong, kEOTFailed, kEOTBroke, kEOTIgnored, kEOTQuit, kEOTTypes};
//enum {kMyEOTCorrect = 0, kMyEOTMissed, kMyEOTEarlyToValid, kMyEOTEarlyToInvalid, kMyEOTBroke, kMyEOTIgnored,
//		kMyEOTQuit, kMyEOTTypes};

#import "GRFSummaryController.h"
#import "GRF.h"
#import "UtilityFunctions.h"

#define kEOTDisplayTimeS		1.0
#define kLastEOTTypeDisplayed   kEOTIgnored				// Count everything up to kEOTIgnored
#define kMyLastEOTTypeDisplayed  kMyEOTIgnored				// Count everything up to kEOTIgnored
#define kPlotBinsDefault		10
#define kTableRows				(kMyLastEOTTypeDisplayed + 6) // extra for blank rows, total, etc.
#define kTrialTableRows			9
#define	kXTickSpacing			100

enum {kBlankRow0 = kMyLastEOTTypeDisplayed + 1, kComputerRow, kBlankRow1, kRewardsRow, kTotalRow};
enum {kColorColumn = 0, kEOTColumn, kDayColumn, kRecentColumn};

NSString *GRFSummaryWindowBrokeKey = @"GRFSummaryWindowBroke";
NSString *GRFSummaryWindowComputerKey = @"GRFSummaryWindowComputer";
NSString *GRFSummaryWindowCorrectKey = @"GRFSummaryWindowCorrect";
NSString *GRFSummaryWindowDateKey = @"GRFSummaryWindowDate";
NSString *GRFSummaryWindowFailedKey = @"GRFSummaryWindowFailed";
NSString *GRFSummaryWindowIgnoredKey = @"GRFSummaryWindowIgnored";
NSString *GRFSummaryWindowTotalKey = @"GRFSummaryWindowTotal";
NSString *GRFSummaryWindowWrongKey = @"GRFSummaryWindowWrong";

NSString *GRFMySummaryBrokeKey = @"GRFMySummaryBroke";
NSString *GRFMySummaryCorrectKey = @"GRFMySummaryCorrect";
NSString *GRFMySummaryMissedKey = @"GRFMySummaryMissed";
NSString *GRFMySummaryIgnoredKey = @"GRFMySummaryIgnored";
NSString *GRFMySummaryEarlyToValidKey = @"GRFMySummaryEarlyToValid";
NSString *GRFMySummaryEarlyToInvalidKey = @"GRFMySummaryEarlyToInvalid";
NSString *GRFMySummaryTotalKey = @"GRFMySummaryTotal";

@implementation GRFSummaryController

- (void)dealloc;
{
	[[task defaults] setFloat:[NSDate timeIntervalSinceReferenceDate] forKey:GRFSummaryWindowDateKey];
	[[task defaults] setInteger:dayEOTs[kEOTBroke] forKey:GRFSummaryWindowBrokeKey];
	[[task defaults] setInteger:dayEOTs[kEOTCorrect] forKey:GRFSummaryWindowCorrectKey];
	[[task defaults] setInteger:dayEOTs[kEOTFailed] forKey:GRFSummaryWindowFailedKey];
	[[task defaults] setInteger:dayEOTs[kEOTIgnored] forKey:GRFSummaryWindowIgnoredKey];
	[[task defaults] setInteger:dayEOTs[kEOTWrong] forKey:GRFSummaryWindowWrongKey];
	[[task defaults] setInteger:dayEOTTotal forKey:GRFSummaryWindowTotalKey];
	[[task defaults] setInteger:dayComputer forKey:GRFSummaryWindowComputerKey];

	[[task defaults] setInteger:myDayEOTs[kEOTBroke] forKey:GRFMySummaryBrokeKey];
	[[task defaults] setInteger:myDayEOTs[kEOTCorrect] forKey:GRFMySummaryCorrectKey];
	[[task defaults] setInteger:myDayEOTs[kEOTFailed] forKey:GRFMySummaryMissedKey];
	[[task defaults] setInteger:myDayEOTs[kEOTIgnored] forKey:GRFMySummaryIgnoredKey];
	[[task defaults] setInteger:myDayEOTs[kEOTWrong] forKey:GRFMySummaryEarlyToValidKey];
	[[task defaults] setInteger:myDayEOTs[kEOTWrong] forKey:GRFMySummaryEarlyToInvalidKey];
	[[task defaults] setInteger:myDayEOTTotal forKey:GRFMySummaryTotalKey];

    [fontAttr release];
    [labelFontAttr release];
    [leftFontAttr release];
    [super dealloc];
}
    
- (id)init;
{
	double timeNow, timeStored;
    
    if ((self = [super initWithWindowNibName:@"GRFSummaryController" defaults:[task defaults]]) != nil) {
		[percentTable reloadData];
        fontAttr = [self makeAttributesForFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
                alignment:NSRightTextAlignment tailIndex:-12];
        [fontAttr retain];
        labelFontAttr = [self makeAttributesForFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
                alignment:NSRightTextAlignment tailIndex:0];
        [labelFontAttr retain];
        leftFontAttr = [self makeAttributesForFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
                alignment:NSLeftTextAlignment tailIndex:0];
        [leftFontAttr retain];
        
        [dayPlot setData:dayEOTs];
        [recentPlot setData:recentEOTs];
    
		lastEOTCode = -1;
		
		timeStored = [[task defaults] floatForKey:GRFSummaryWindowDateKey];
		timeNow = [NSDate timeIntervalSinceReferenceDate];
		if (timeNow - timeStored < 12 * 60 * 60) {			// Less than 12 h old?
			dayEOTs[kEOTBroke] = [[task defaults] integerForKey:GRFSummaryWindowBrokeKey];
			dayEOTs[kEOTCorrect] = [[task defaults] integerForKey:GRFSummaryWindowCorrectKey];
			dayEOTs[kEOTFailed] = [[task defaults] integerForKey:GRFSummaryWindowFailedKey];
			dayEOTs[kEOTIgnored] = [[task defaults] integerForKey:GRFSummaryWindowIgnoredKey];
			dayEOTs[kEOTWrong] = [[task defaults] integerForKey:GRFSummaryWindowWrongKey];
			dayEOTTotal = [[task defaults] integerForKey:GRFSummaryWindowTotalKey];
			dayComputer = [[task defaults] integerForKey:GRFSummaryWindowComputerKey];

			myDayEOTs[kMyEOTBroke] = [[task defaults] integerForKey:GRFMySummaryBrokeKey];
			myDayEOTs[kMyEOTCorrect] = [[task defaults] integerForKey:GRFMySummaryCorrectKey];
			myDayEOTs[kMyEOTMissed] = [[task defaults] integerForKey:GRFMySummaryMissedKey];
			myDayEOTs[kMyEOTIgnored] = [[task defaults] integerForKey:GRFMySummaryIgnoredKey];
			myDayEOTs[kMyEOTEarlyToValid] = [[task defaults] integerForKey:GRFMySummaryEarlyToValidKey];
			myDayEOTs[kMyEOTEarlyToInvalid] = [[task defaults] integerForKey:GRFMySummaryEarlyToInvalidKey];
			myDayEOTTotal = [[task defaults] integerForKey:GRFMySummaryTotalKey];
		}
    }
    return self;
}

- (NSDictionary *)makeAttributesForFont:(NSFont *)font alignment:(NSTextAlignment)align tailIndex:(float)indent {

	NSMutableParagraphStyle *para; 
    NSMutableDictionary *attr;
    
        para = [[NSMutableParagraphStyle alloc] init];
        [para setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
        [para setAlignment:align];
        [para setTailIndent:indent];
        
        attr = [[NSMutableDictionary alloc] init];
        [attr setObject:font forKey:NSFontAttributeName];
        [attr setObject:para forKey:NSParagraphStyleAttributeName];
        [attr autorelease];
        [para release];
        return attr;
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
{
	if (tableView == trialTable) {
		return kTrialTableRows;
	}
	else {
		return kTableRows;
	}
}

// Return an NSAttributedString for a cell in the percent performance table

- (id)percentTableColumn:(NSTableColumn *)tableColumn row:(long)row {

    long column;
    NSString *string;
	NSDictionary *attr = fontAttr;
	NSString *eotStrings[] = {@"Correct", @"Missed", @"Early Val", @"Early Inval", @"Broke", @"Ignored"};
 
    if (row == kBlankRow0 || row == kBlankRow1) {		// the blank rows
        return @" ";
    }
    column = [[tableColumn identifier] intValue];
    switch (column) {
		case kColorColumn:
            string = @" ";
			break;
        case kEOTColumn:
			attr = labelFontAttr;
            switch (row) {
                case kTotalRow:
                    string = @"Total:";
                    break;
				case kRewardsRow:
					string = @"Rewards:";
					break;
				case kComputerRow:					// row for computer failures
                    string = @"Computer:";
					break;
                default:
  //                  string = [NSString stringWithFormat:@"%@:", 
//								[LLStandardDataEvents trialEndName:kLastEOTTypeDisplayed - row]];
					string = eotStrings[kMyLastEOTTypeDisplayed - row];
                    break;
            }
            break;
        case kDayColumn:
            if (row == kTotalRow) {
                string = [NSString stringWithFormat:@"%ld", myDayEOTTotal];
            }
            else if (row == kRewardsRow) {
                string = [NSString stringWithFormat:@"%ld", myDayEOTs[kMyEOTCorrect]];
            }
            else if (myDayEOTTotal == 0) {
                string = @" ";
            }
			else if (row == kComputerRow) {		// row reserved for computer failures
               string = [NSString stringWithFormat:@"%ld", dayComputer];
			}
            else {
               string = [NSString stringWithFormat:@"%ld%%", 
							(long)round(myDayEOTs[kMyLastEOTTypeDisplayed - row] * 100.0 / myDayEOTTotal)];
            }
            break;
       case kRecentColumn:
            if (row == kTotalRow) {
                string = [NSString stringWithFormat:@"%ld", myRecentEOTTotal];
            }
            else if (row == kRewardsRow) {
                string = [NSString stringWithFormat:@"%ld", myRecentEOTs[kEOTCorrect]];
            }
            else if (recentEOTTotal == 0) {
                string = @" ";
            }
			else if (row == kComputerRow) {		// row reserved for computer failures
               string = [NSString stringWithFormat:@"%ld", recentComputer];
			}
           else {
				if (myRecentEOTTotal == 0) {
					string = @"";
				}
				else {
					string = [NSString stringWithFormat:@"%ld%%", 
							(long)round(myRecentEOTs[kMyLastEOTTypeDisplayed - row] * 100.0 / myRecentEOTTotal)];
				}
            }
            break;
        default:
            string = @"???";
            break;
    }
	return [[[NSAttributedString alloc] initWithString:string attributes:attr] autorelease];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    if (tableView == percentTable) {
        return [self percentTableColumn:tableColumn row:row];
    }
    else if (tableView == trialTable) {
        return [self trialTableColumn:tableColumn row:row];
    }
    else {
        return @"";
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
{
	return NO;
}

// Display the color patches showing the EOT color coding, and highlight the text for the last EOT type

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn 					row:(int)rowIndex {

	long column;
	long colorMapping[] = {4, 3, 5, 1, 2, 0};
	
	if (tableView != percentTable) {
		return;
	}
	column = [[tableColumn identifier] intValue];
	if (column == kColorColumn) {
		[cell setDrawsBackground:YES]; 
		if (rowIndex <= kMyLastEOTTypeDisplayed) {
			[cell setBackgroundColor:[LLStandardDataEvents eotColor:colorMapping[rowIndex]]];
		}
		else {
			[cell setBackgroundColor:[NSColor whiteColor]];
		}
	}
	else {
		if (!newTrial && (lastEOTCode >= 0) && (lastEOTCode == (kMyLastEOTTypeDisplayed - rowIndex))) {
			[cell setBackgroundColor:[NSColor controlHighlightColor]];
		}
		else {
			[cell setBackgroundColor:[NSColor whiteColor]];
		}
	}
}

- (id)trialTableColumn:(NSTableColumn *)tableColumn row:(long)row;
{
    long index, repsDone, repsPerSide, column, remainingTrials, remainingStim, doneStim;
    double timeLeftS;
    NSAttributedString *cellContents;
    NSString *string;
	BlockStatus *pBS = &blockStatus;
	MappingBlockStatus *pMBS = &mappingBlockStatus;
	
	static BOOL initialized = NO;
	
	initialized = (initialized | newTrial);

// Do nothing if the data buffers have nothing in them

    if ((column = [[tableColumn identifier] intValue]) != 0) {
        return @"";
    }
	
    switch (row) {
        case 0:
            if (!initialized) {
                string = @" ";
            }
			else {
				if (trial.catchTrial) {
					string = [NSString stringWithFormat:@"%s trial catch trial", newTrial ? "This" : "Last"];
				}
				else if (trial.instructTrial) {
					string = [NSString stringWithFormat:@"%s trial %.*f deg change instruction", 
							newTrial ? "This" : "Last",
							(int)[LLTextUtil precisionForValue:trial.orientationChangeDeg significantDigits:2],
							trial.orientationChangeDeg];
				}
				else {
					string = [NSString stringWithFormat:@"%s trial %.*f deg change", 
							newTrial ? "This" : "Last",
							(int)[LLTextUtil precisionForValue:trial.orientationChangeDeg significantDigits:2],
							trial.orientationChangeDeg];
				}
			}
			break;
        case 1:
        case 5:
			string = @"";
			break;
        case 2:
			repsPerSide = repsDone = 0;
			for (index = 0; index < pBS->changes; index++) {
				repsPerSide += pBS->validReps[index] + pBS->invalidReps[index];
				repsDone += pBS->validRepsDone[index] + pBS->invalidRepsDone[index];
			}
            string = [NSString stringWithFormat:@"Trial %ld of %ld", repsDone + 1, repsPerSide];
            break;
		case 3: 
            string = [NSString stringWithFormat:@"Block %ld of %ld", pBS->blocksDone + 1, pBS->blockLimit];
            break;
        case 4:
			repsPerSide = repsDone = 0;
			for (index = 0; index < pBS->changes; index++) {
				repsPerSide += pBS->validReps[index] + pBS->invalidReps[index];
				repsDone += pBS->validRepsDone[index] + pBS->invalidRepsDone[index];
			}
           remainingTrials =  MAX(0, (pBS->blockLimit - pBS->blocksDone) * repsPerSide * kLocations
						- pBS->sidesDone * repsPerSide - repsDone);
                string = [NSString stringWithFormat:@"Remaining: %ld stimuli", remainingTrials];
			break;
        case 6:
			string = [NSString stringWithFormat:@"Stimulus %ld of %ld", 
					mappingBlockStatus.stimDone + 1, mappingBlockStatus.stimLimit];
			break;
        case 7:
			string = [NSString stringWithFormat:@"Block %ld of %ld", pMBS->blocksDone + 1, pMBS->blockLimit];
			break;
		case 8:
			doneStim = pMBS->stimDone + pMBS->stimLimit * pMBS->blocksDone;
			remainingStim = MAX(0, pMBS->stimLimit * pMBS->blockLimit - doneStim);
            if (doneStim == 0) {
				if (remainingStim > 0) {
					string = [NSString stringWithFormat:@"Remaining: %ld stimuli", remainingStim];
            }
            else {
					string = @"";
				}
            }
            else {
                timeLeftS = ([LLSystemUtil getTimeS] - lastStartTimeS + accumulatedRunTimeS)
													/ doneStim * remainingStim;
                if (timeLeftS < 60.0) {
                    string = [NSString stringWithFormat:@"Remaining: %ld stimuli (%.1f s)", 
                                remainingStim, timeLeftS];
                }
                else if (timeLeftS < 3600.0) {
                    string = [NSString stringWithFormat:@"Remaining: %ld stimuli (%.1f m)", 
                                remainingStim, timeLeftS / 60.0];
                }
                else {
                    string = [NSString stringWithFormat:@"Remaining: %ld stimuli (%.1f h)", 
                                remainingStim, timeLeftS / 3600.0];
                }
            }
			break;
        default:
            string = @"???";
            break;
    }
    cellContents = [[NSAttributedString alloc] initWithString:string attributes:leftFontAttr];
	[cellContents autorelease];
    return cellContents;
}

// Methods related to data events follow:

- (void)blockStatus:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&blockStatus length:sizeof(BlockStatus)];
}

- (void) dirChangeStimParams:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&stimParams length:sizeof(StimParams)];
}

- (void)mappingBlockStatus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&mappingBlockStatus length:sizeof(MappingBlockStatus)];
	[trialTable reloadData];
}

// Save our trial end code for processing when the final trial end occurs.  The EOT plots
// are driven off Lablib EOT codes, which are taken from the trialEnd event.  The myTrialEnd
// codes are used only for the percentage recored.

- (void) myTrialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long eotCode;
	
	[eventData getBytes:&eotCode length:sizeof(long)];
	lastEOTCode = eotCode;
    if (eotCode <= kMyLastEOTTypeDisplayed) {
        myRecentEOTs[eotCode]++;
        myRecentEOTTotal++;  
        myDayEOTs[eotCode]++;
        myDayEOTTotal++;  
    }
    [percentTable reloadData];
}

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long index;
    
    recentComputer = recentEOTTotal = myRecentEOTTotal = 0;
    for (index = 0; index <= kLastEOTTypeDisplayed; index++) {
        recentEOTs[index] = 0;
    }
    for (index = 0; index <= kMyLastEOTTypeDisplayed; index++) {
        myRecentEOTs[index] = 0;
    }
    accumulatedRunTimeS = 0;
    if (taskMode == kTaskRunning) {
        lastStartTimeS = [LLSystemUtil getTimeS];
    }
	[eotHistory reset];
	[percentTable reloadData];
	[trialTable reloadData];
}

- (void) taskMode:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&taskMode length:sizeof(long)];
    switch (taskMode) {
        case kTaskRunning:
            lastStartTimeS = [LLSystemUtil getTimeS];
            break;
        case kTaskStopping:
            accumulatedRunTimeS += [LLSystemUtil getTimeS] - lastStartTimeS;
            break;
        default:
            break;
    }
}

- (void) trialCertify:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	long certifyCode; 
	
	[eventData getBytes:&certifyCode length:sizeof(long)];
    if (certifyCode != 0) { // -1 because computer errors stored separately
        recentComputer++;  
        dayComputer++;  
    }
}

- (void) trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long eotCode;
	
	[eventData getBytes:&eotCode length:sizeof(long)];

	if (eotCode <= kLastEOTTypeDisplayed) {
        recentEOTs[eotCode]++;
        recentEOTTotal++;  
        dayEOTs[eotCode]++;
        dayEOTTotal++;  
    }
    newTrial = NO;
	[eotHistory addEOT:eotCode];
	[trialTable reloadData];
	[dayPlot setNeedsDisplay:YES];
	[recentPlot setNeedsDisplay:YES];
}

- (void) trial:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&trial length:sizeof(TrialDesc)];
    newTrial = YES;
	[trialTable reloadData];
    [percentTable reloadData];
}

@end
