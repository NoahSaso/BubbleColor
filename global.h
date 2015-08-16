#define XLog(z) NSLog(@"[%@] %@", kName, z)
#define Xstr(z, ...) [NSString stringWithFormat:z, ##__VA_ARGS__]
#define XIS_EMPTY(z) (!z || [(NSString *)z length] < 1)
