//
//  MIKMIDICommand.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

typedef NS_ENUM(NSUInteger, MIKMIDICommandType) {
	MIKMIDICommandTypeNoteOff = 0x8f,
	MIKMIDICommandTypeNoteOn = 0x9f,
	MIKMIDICommandTypePolyphonicKeyPressure = 0xaf,
	MIKMIDICommandTypeControlChange = 0xbf,
	MIKMIDICommandTypeProgramChange = 0xcf,
	MIKMIDICommandTypeChannelPressure = 0xdf,
	MIKMIDICommandTypePitchWheelChange = 0xef,
	
	MIKMIDICommandTypeSystemMessage = 0xff,
	MIKMIDICommandTypeSystemExclusive = 0xf0,
	MIKMIDICommandTypeSystemTimecodeQuarterFrame = 0xf1,
	MIKMIDICommandTypeSystemSongPositionPointer = 0xf2,
	MIKMIDICommandTypeSystemSongSelect = 0xf3,
	MIKMIDICommandTypeSystemTuneRequest = 0xf6,

	MIKMIDICommandTypeSystemTimingClock = 0xf8,
	MIKMIDICommandTypeSystemStartSequence = 0xfa,
	MIKMIDICommandTypeSystemContinueSequence = 0xfb,
	MIKMIDICommandTypeSystemStopSequence = 0xfc,
	MIKMIDICommandTypeSystemKeepAlive = 0xfe,
};

@class MIKMIDIMappingItem;

@interface MIKMIDICommand : NSObject <NSCopying>

+ (instancetype)commandWithMIDIPacket:(MIDIPacket *)packet;
+ (instancetype)commandForCommandType:(MIKMIDICommandType)commandType; // Most useful for mutable commands

@property (nonatomic, strong, readonly) NSDate *timestamp;
@property (nonatomic, readonly) MIKMIDICommandType commandType;
@property (nonatomic, readonly) UInt8 dataByte1;
@property (nonatomic, readonly) UInt8 dataByte2;

@property (nonatomic, readonly) MIDITimeStamp midiTimestamp;
@property (nonatomic, copy, readonly) NSData *data;

// Must be set by client code that handles receiving MIDI commands. Allows responders to understand how a command was mapped, especially useful to determine interaction type.
@property (nonatomic, strong) MIKMIDIMappingItem *mappingItem;

@end

@interface MIKMutableMIDICommand : MIKMIDICommand

@property (nonatomic, strong, readwrite) NSDate *timestamp;
@property (nonatomic, readwrite) MIKMIDICommandType commandType;
@property (nonatomic, readwrite) UInt8 dataByte1;
@property (nonatomic, readwrite) UInt8 dataByte2;

@property (nonatomic, readwrite) MIDITimeStamp midiTimestamp;
@property (nonatomic, copy, readwrite) NSData *data;

// Must be set by client code that handles receiving MIDI commands. Allows responders to understand how a command was mapped, especially useful to determine interaction type.
@property (nonatomic, strong) MIKMIDIMappingItem *mappingItem;

@end

// Pass 0 for listSize to use standard MIDIPacketList size (i.e. sizeof(MIDIPacketList) )
BOOL MIKMIDIPacketListFromCommands(MIDIPacketList *inOutPacketList, ByteCount listSize, NSArray *commands);

