#import "ArtemisBitSet.h"

/*
 * BitSets are packed into arrays of "words."  Currently a word
 * consists of 32 bits, requiring 5 address bits.
 */
const int ADDRESS_BITS_PER_WORD = 5;
const int64_t BITS_PER_WORD = 1 << ADDRESS_BITS_PER_WORD; // 32
const int64_t WORD_MASK = 0xffffffff;

@implementation ArtemisBitSet

- (instancetype)init {
    return [self initWithCapacity:0];
}

- (instancetype)initWithCapacity:(int) nbits {
    if (self = [super init]) {
        if (nbits > 0)
        {
            let size = (((nbits-1) >> ADDRESS_BITS_PER_WORD)+1);
            mWords = malloc(sizeof(uint)*size);
            for (int i=0; i<size; i++) mWords[i] = 0;
            mLength = size;
        } else {
            mLength = 0;
        }
    }
    return self;
}

- (void) dealloc {
    free(mWords);
}

- (bool) isEmpty { return mLength == 0; }
- (uint) word:(int) index { return mWords[index]; }
- (int) length { return mLength; }
- (void) clear { [self clear:-1]; }

- (void) clear:(int) bitIndex {
    if (bitIndex == -1)  {
        var wordsInUse = mLength;
        while (wordsInUse>0) 
        {
            mWords[--wordsInUse] = 0;
        }
        return;
    }

    let wordIndex = bitIndex >> ADDRESS_BITS_PER_WORD;
    if (mLength <= wordIndex)
        mWords = realloc(mWords, sizeof(uint)*wordIndex+1);
    mWords[wordIndex] &= ~(1 << bitIndex);
}

- (void) set:(int) bitIndex{
    [self set:bitIndex to:true];
}

- (void) set:(int) bitIndex to:(bool)value {
    let wordIndex = bitIndex >> ADDRESS_BITS_PER_WORD;
    let wordsInUse = mLength;
    var wordsRequired = wordIndex+1;

    if (wordIndex >= mLength) 
    {        
        mWords = realloc(mWords, sizeof(uint)*wordIndex+1);
    }
    if (wordsInUse < wordsRequired) 
    {
        mWords = realloc(mWords, sizeof(uint)*Max(2 * wordsInUse, wordsRequired));
        mLength = wordsRequired;
        for (int i=wordsInUse, l=mLength; i<l; i++) 
        {
            mWords[i] = 0;
        }
    }

    if (value) 
    {
        mWords[wordIndex] |= (1 << bitIndex);
    } 
    else 
    {
        mWords[wordIndex] &= ~(1 << bitIndex);
    }
}

- (bool) get:(int) bitIndex {
    let wordIndex = bitIndex >> ADDRESS_BITS_PER_WORD;
    let wordsInUse = mLength;

    return (wordIndex < wordsInUse) && ((mWords[wordIndex] & (1 << bitIndex)) != 0);
}


/**
 * Returns true if the specified BitSet has any bits set to true that are also set to true in this BitSet.
 */
- (bool) intersects:(ArtemisBitSet*) set {
    let wordsInUse = mLength;

    for (int i = Min(wordsInUse, set.length) - 1; i >= 0; i--)
        if ((mWords[i] & [set word:i]) != 0) 
            return true;
    return false;
}

/** 
 * Returns the index of the first bit that is set to true that occurs on or after the specified starting index.
 */
- (int) nextSetBit:(int) fromIndex {
    var u = fromIndex >> ADDRESS_BITS_PER_WORD;
    let wordsInUse = mLength;

    var word = mWords[u] & (WORD_MASK << fromIndex);
    while (true) 
    {
        if (word != 0)
            return (int)((u * BITS_PER_WORD) + [self numberNSTrailingZeros:word]);
        if (++u == wordsInUse)
            return -1;
        word = mWords[u];
    }

}

- (uint) numberNSTrailingZeros:(uint)i {
    if (i == 0) return 32;
    uint x = i;
    uint y;
    uint n = 31;
    y = x << 16; if (y != 0) { n -= 16; x = y; }
    y = x <<  8; if (y != 0) { n -=  8; x = y; }
    y = x <<  4; if (y != 0) { n -=  4; x = y; }
    y = x <<  2; if (y != 0) { n -=  2; x = y; }
    return (n - ((x << 1) >> 31));

}

- (NSString *)description {
	NSMutableString* s = [NSMutableString string];
    let size = mLength * BITS_PER_WORD;
	
	[s appendFormat:@"[BitSet(%li):", size];
	for( int i=0; i<size; i++ ) {
		[s appendString: [self get:i] ? @"1" : @"0" ];
	}
	[s appendString:@"]"];
	return s;
}


@end