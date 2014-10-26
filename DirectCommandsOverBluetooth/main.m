#import <Foundation/NSObject.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothDeviceInquiry.h>
#import <IOBluetooth/objc/IOBluetoothHostController.h>
#import <IOBluetooth/objc/IOBluetoothSDPServiceRecord.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>

@interface Discoverer : NSObject <IOBluetoothRFCOMMChannelDelegate> {}
- (void)sendData:(NSString *)string toChannel:(IOBluetoothRFCOMMChannel*)rfcommChannel;
- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength;
- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel status:(IOReturn)error;
- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel*)rfcommChannel;
- (void)rfcommChannelControlSignalsChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel;
- (void)rfcommChannelFlowControlChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel;
- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel refcon:(void*)refcon status:(IOReturn)error;
- (void)rfcommChannelQueueSpaceAvailable:(IOBluetoothRFCOMMChannel*)rfcommChannel;
@end

@implementation Discoverer

- (void)sendData:(NSString *)string toChannel:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
    int i;
    // Turn the string into data.
    NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
    char buffer[ [data length] +4];
    char *bytes = (char *) [data bytes];
    // Add a CRLF to the start
    buffer[0] = 13;
    buffer[1] = 10;
    // Copy the data into the buffer.
    for (i=0;i<[data length];i++)
    {
        buffer[2+i] = bytes[i];
    }
    // Append a CRLF
    buffer[ [data length]+2]  = 13;
    buffer[ [data length]+3]  = 10;
    // Synchronously write the data to the channel.
    IOReturn ret = [rfcommChannel writeSync:&buffer length:[data length]+4];
    NSLog(@"IORetrun = %d", ret);
}

- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength
{
    NSLog(@"rfcommChannelData");
}

- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel status:(IOReturn)error
{
    NSLog(@"%d : Channel Open Complete %p %d",[rfcommChannel getChannelID],rfcommChannel,error);
    NSLog(@"rfcommChannelOpenComplete");
    [self sendData:@"0f0000008000009401810282e80382e803" toChannel:rfcommChannel];
}

- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
    NSLog(@"rfcommChannelClosed");
}

- (void)rfcommChannelControlSignalsChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
    NSLog(@"rfcommChannelControlSignalsChanged");
}

- (void)rfcommChannelFlowControlChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
    NSLog(@"rfcommChannelFlowControlChanged");
}

- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel refcon:(void*)refcon status:(IOReturn)error
{
    NSLog(@"rfcommChannelWriteComplete");
}

- (void)rfcommChannelQueueSpaceAvailable:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
    NSLog(@"rfcommChannelQueueSpaceAvailable");
}

@end

int main(int argc, const char *argv[])
{
    @autoreleasepool
    {
        Discoverer *d = [[Discoverer alloc] init];
        IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddressString:@"00165341710A"];
        IOBluetoothRFCOMMChannel *rfCommChannel;
        IOBluetoothSDPUUID *sppServiceUUID = [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassSerialPort];
        
        IOBluetoothSDPServiceRecord	*sppServiceRecord = [device getServiceRecordForUUID:sppServiceUUID];
        
        if ( sppServiceRecord == nil )
        {
            NSLog( @"Error - no spp service in selected device." );
        }
        
        UInt8	rfcommChannelID;
        if ( [sppServiceRecord getRFCOMMChannelID:&rfcommChannelID] != kIOReturnSuccess )
        {
            NSLog( @"Error - no spp service in selected device." );
        }
        NSLog(@"%hhu", rfcommChannelID);
        
        if ( ( [device openRFCOMMChannelAsync:&rfCommChannel withChannelID:rfcommChannelID delegate:d] != kIOReturnSuccess ) && ( rfCommChannel != nil ) )
        {
            NSLog( @"Error - open sequence failed.***\n" );
        }
        
        CFRunLoopRun();
    }
    
    return 0;
}