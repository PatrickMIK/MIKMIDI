//
//  MIKMIDIObject.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/8/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIObject.h"
#import "MIKMIDIDevice.h"
#import "MIKMIDIEntity.h"
#import "MIKMIDIEndpoint.h"
#import "MIKMIDIUtilities.h"

static NSMutableSet *registeredMIKMIDIObjectSubclasses;

@interface MIKMIDIObject ()

@property (nonatomic, readwrite) MIDIObjectRef objectRef;
@property (nonatomic, readwrite) MIDIUniqueID uniqueID;
@property (nonatomic, readwrite, getter = isOnline) BOOL online;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *displayName;

@end

@implementation MIKMIDIObject

+ (void)registerSubclass:(Class)subclass;
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		registeredMIKMIDIObjectSubclasses = [[NSMutableSet alloc] init];
	});
	[registeredMIKMIDIObjectSubclasses addObject:subclass];
}

+ (NSArray *)representedMIDIObjectTypes; { return @[]; }

+ (BOOL)canInitWithObjectRef:(MIDIObjectRef)objectRef;
{
	NSError *error = nil;
	MIDIObjectType objectType = MIKMIDIObjectTypeOfObject(objectRef, &error);
	if (error) {
		NSLog(@"Unable to get object type of %d: %@", (int)objectRef, error);
		return NO;
	}
	return [[self representedMIDIObjectTypes] containsObject:@(objectType)];
}

+ (instancetype)MIDIObjectWithObjectRef:(MIDIObjectRef)objectRef;
{
	if (objectRef == 0) return nil;
	Class resultSubclass = nil;
	for (Class subclass in registeredMIKMIDIObjectSubclasses) {
		if ([subclass canInitWithObjectRef:objectRef]) {
			resultSubclass = subclass;
			break;
		}
	}
	if (!resultSubclass) return nil;
	
	return [[resultSubclass alloc] initWithObjectRef:objectRef];
}

- (id)init
{
	[NSException raise:NSInternalInconsistencyException format:@"MIKMIDIObjects should be initialized using -initWithObjectRef:"];
	self = nil;
	return nil;
}

- (id)initWithObjectRef:(MIDIObjectRef)objectRef
{
	if (![[self class] canInitWithObjectRef:objectRef]) {
		self = nil;
		return nil;
	}
	
    self = [super init];
    if (self) {
        _objectRef = objectRef;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
	if (![[object class] isEqual:[self class]]) return NO;
	
	return self.uniqueID == [(MIKMIDIObject *)object uniqueID];
}

- (NSUInteger)hash { return self.uniqueID; }

- (NSString *)description
{
	NSString *name = self.displayName ? self.displayName : self.name;
	return [NSString stringWithFormat:@"%@ %@", [super description], name];
}

#pragma mark - Private

#pragma mark - Properties

- (MIDIUniqueID)uniqueID
{
	if (!_uniqueID) {
		NSError *error = nil;
		MIDIUniqueID value = MIKIntegerPropertyFromMIDIObject(self.objectRef, kMIDIPropertyUniqueID, &error);
		if (error) {
			NSLog(@"Unable to get MIDI device unique ID: %@", error);
			return 0;
		}
		self.uniqueID = value;
	}
	return _uniqueID;
}

- (BOOL)isOnline
{
	NSError *error = nil;
	SInt32 offline = MIKIntegerPropertyFromMIDIObject(self.objectRef, kMIDIPropertyOffline, &error);
	if (error) {
		NSLog(@"Unable to get offline status for MIDI object %@", self);
		return NO;
	}
	
	return offline == 0;
}

- (NSString *)name
{
	if (!_name) {
		self.name = MIKStringPropertyFromMIDIObject(self.objectRef, kMIDIPropertyName, NULL);
	}
	return _name;
}

- (NSString *)displayName
{
	if (!_displayName) {
		NSError *error = nil;
		NSString *value = MIKStringPropertyFromMIDIObject(self.objectRef, kMIDIPropertyDisplayName, &error);
		if (value) self.displayName = value;
	}
	
	return _displayName ? _displayName : self.name;
}

@end
