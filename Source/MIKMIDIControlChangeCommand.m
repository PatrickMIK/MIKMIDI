//
//  MIKMIDIControlChangeCommand.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIControlChangeCommand.h"
#import "MIKMIDICommand_SubclassMethods.h"

@interface MIKMIDIControlChangeCommand ()

@property (nonatomic, readwrite, getter = isFourteenBitCommand) BOOL fourteenBitCommand;

@end

@implementation MIKMIDIControlChangeCommand

+ (void)load { [super load]; [MIKMIDICommand registerSubclass:self]; }
+ (BOOL)supportsMIDICommandType:(MIKMIDICommandType)type { return type == MIKMIDICommandTypeControlChange; }
+ (Class)immutableCounterpartClass; { return [MIKMIDIControlChangeCommand class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDIControlChangeCommand class]; }

+ (instancetype)commandByCoalescingMSBCommand:(MIKMIDIControlChangeCommand *)msbCommand andLSBCommand:(MIKMIDIControlChangeCommand *)lsbCommand;
{
	if (!msbCommand || !lsbCommand) return nil;
	
	if (![msbCommand isKindOfClass:[MIKMIDIControlChangeCommand class]] ||
		![lsbCommand isKindOfClass:[MIKMIDIControlChangeCommand class]]) return nil;
	
	if (msbCommand.controllerNumber > 31) return nil;
	if (lsbCommand.controllerNumber < 32 || lsbCommand.controllerNumber > 63) return nil;
	
	if (lsbCommand.controllerNumber - msbCommand.controllerNumber != 32) return nil;
	
	MIKMIDIControlChangeCommand *result = [[MIKMIDIControlChangeCommand alloc] init];
	result.internalData = [msbCommand.data mutableCopy];
	result.fourteenBitCommand = YES;
	[result.internalData appendData:[lsbCommand.data subdataWithRange:NSMakeRange(2, 1)]];

	return result;
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"%@ control number: %lu value: %lu 14-bit? %i", [super description], (unsigned long)self.controllerNumber, (unsigned long)self.controllerValue, self.isFourteenBitCommand];
}

- (id)copyWithZone:(NSZone *)zone
{
	MIKMIDIControlChangeCommand *result = [super copyWithZone:zone];
	result.fourteenBitCommand = self.isFourteenBitCommand;
	return result;
}

- (id)mutableCopy
{
	MIKMIDIControlChangeCommand *result = [super mutableCopy];
	result.fourteenBitCommand = self.isFourteenBitCommand;
	return result;
}

#pragma mark - Properties

- (NSUInteger)controllerNumber { return self.dataByte1; }

- (NSUInteger)controllerValue { return self.value; }

- (NSUInteger)fourteenBitValue
{
	NSUInteger MSB = ([super value] << 7) & 0x3F80;
	NSUInteger LSB = 0;
	if ([self.data length] > 3) {
		UInt8 *data = (UInt8 *)[self.data bytes];
		LSB = data[3] & 0x7F;
	}
	
	return MSB + LSB;
}

@end

@implementation MIKMutableMIDIControlChangeCommand

+ (BOOL)supportsMIDICommandType:(MIKMIDICommandType)type; { return [MIKMIDIControlChangeCommand supportsMIDICommandType:type]; }
+ (Class)immutableCounterpartClass; { return [MIKMIDIControlChangeCommand immutableCounterpartClass]; }
+ (Class)mutableCounterpartClass; { return [MIKMIDIControlChangeCommand mutableCounterpartClass]; }

- (id)copyWithZone:(NSZone *)zone
{
	MIKMutableMIDIControlChangeCommand *result = [super copyWithZone:zone];
	result.fourteenBitCommand = self.isFourteenBitCommand;
	return result;
}

- (id)mutableCopy
{
	MIKMutableMIDIControlChangeCommand *result = [super mutableCopy];
	result.fourteenBitCommand = self.isFourteenBitCommand;
	return result;
}

#pragma mark - Properties

- (NSUInteger)fourteenBitValue
{
	NSUInteger MSB = ([super value] << 7) & 0x3F80;
	NSUInteger LSB = 0;
	if ([self.data length] > 3) {
		UInt8 *data = (UInt8 *)[self.data bytes];
		LSB = data[3] & 0x7F;
	}
	
	return MSB + LSB;
}

- (void)setFourteenBitValue:(NSUInteger)value
{
	NSUInteger MSB = (value >> 7) & 0x7F;
	NSUInteger LSB = self.isFourteenBitCommand ? value & 0x7F : 0;
	
	[super setValue:MSB];
	if ([self.internalData length] < 4) [self.internalData increaseLengthBy:4-[self.internalData length]];
	[self.internalData replaceBytesInRange:NSMakeRange(3, 1) withBytes:&LSB length:1];
}

- (NSUInteger)controllerNumber { return self.dataByte1; }
- (void)setControllerNumber:(NSUInteger)value { self.dataByte1 = value; }

- (NSUInteger)controllerValue { return self.value; }
- (void)setControllerValue:(NSUInteger)value { self.value = value; }

@end