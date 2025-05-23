// 遇到问题联系中文翻译作者：pxx917144686
//
//  FLEXRuntimeSafety.m
//  FLEX
//
//  由 Tanner 创建于 3/25/17.
//

#import "FLEXRuntimeSafety.h"

NSUInteger const kFLEXKnownUnsafeClassCount = 19;
Class * _UnsafeClasses = NULL;
CFSetRef FLEXKnownUnsafeClasses = nil;
CFSetRef FLEXKnownUnsafeIvars = nil;

#define FLEXClassPointerOrCFNull(name) \
    (NSClassFromString(name) ?: (__bridge id)kCFNull)

#define FLEXIvarOrCFNull(cls, name) \
    (class_getInstanceVariable([cls class], name) ?: (void *)kCFNull)

__attribute__((constructor))
static void FLEXRuntimeSafteyInit(void) {
    FLEXKnownUnsafeClasses = CFSetCreate(
        kCFAllocatorDefault,
        (const void **)(uintptr_t)FLEXKnownUnsafeClassList(),
        kFLEXKnownUnsafeClassCount,
        nil
    );

    Ivar unsafeIvars[] = {
        FLEXIvarOrCFNull(NSURL, "_urlString"),
        FLEXIvarOrCFNull(NSURL, "_baseURL"),
    };
    FLEXKnownUnsafeIvars = CFSetCreate(
        kCFAllocatorDefault,
        (const void **)unsafeIvars,
        sizeof(unsafeIvars),
        nil
    );
}

const Class * FLEXKnownUnsafeClassList(void) {
    if (!_UnsafeClasses) {
        const Class ignored[] = {
            FLEXClassPointerOrCFNull(@"__ARCLite__"),
            FLEXClassPointerOrCFNull(@"__NSCFCalendar"),
            FLEXClassPointerOrCFNull(@"__NSCFTimer"),
            FLEXClassPointerOrCFNull(@"NSCFTimer"),
            FLEXClassPointerOrCFNull(@"__NSGenericDeallocHandler"),
            FLEXClassPointerOrCFNull(@"NSAutoreleasePool"),
            FLEXClassPointerOrCFNull(@"NSPlaceholderNumber"),
            FLEXClassPointerOrCFNull(@"NSPlaceholderString"),
            FLEXClassPointerOrCFNull(@"NSPlaceholderValue"),
            FLEXClassPointerOrCFNull(@"Object"),
            FLEXClassPointerOrCFNull(@"VMUArchitecture"),
            FLEXClassPointerOrCFNull(@"JSExport"),
            FLEXClassPointerOrCFNull(@"__NSAtom"),
            FLEXClassPointerOrCFNull(@"_NSZombie_"),
            FLEXClassPointerOrCFNull(@"_CNZombie_"),
            FLEXClassPointerOrCFNull(@"__NSMessage"),
            FLEXClassPointerOrCFNull(@"__NSMessageBuilder"),
            FLEXClassPointerOrCFNull(@"FigIrisAutoTrimmerMotionSampleExport"),
            // 临时措施，直到我们有了自己的类型编码解析器；
            // setVectors: 的类型编码无效，会导致 NSMethodSignature 崩溃
            FLEXClassPointerOrCFNull(@"_UIPointVector"),
        };
        
        assert((sizeof(ignored) / sizeof(Class)) == kFLEXKnownUnsafeClassCount);

        _UnsafeClasses = (Class *)malloc(sizeof(ignored));
        memcpy(_UnsafeClasses, ignored, sizeof(ignored));
    }

    return _UnsafeClasses;
}

NSSet * FLEXKnownUnsafeClassNames(void) {
    static NSSet *set = nil;
    if (!set) {
        NSArray *ignored = @[
            @"__ARCLite__",
            @"__NSCFCalendar",
            @"__NSCFTimer",
            @"NSCFTimer",
            @"__NSGenericDeallocHandler",
            @"NSAutoreleasePool",
            @"NSPlaceholderNumber",
            @"NSPlaceholderString",
            @"NSPlaceholderValue",
            @"Object",
            @"VMUArchitecture",
            @"JSExport",
            @"__NSAtom",
            @"_NSZombie_",
            @"_CNZombie_",
            @"__NSMessage",
            @"__NSMessageBuilder",
            @"FigIrisAutoTrimmerMotionSampleExport",
            @"_UIPointVector",
        ];

        set = [NSSet setWithArray:ignored];
        assert(set.count == kFLEXKnownUnsafeClassCount);
    }

    return set;
}
