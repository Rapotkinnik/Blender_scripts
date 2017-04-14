id objects[] = { someObject, @"Hello, World!", @42 };
NSUInteger count = sizeof(objects) / sizeof(id);
NSArray *array = [NSArray arrayWithObjects:objects
                  count:count];

или так:
NSArray *array = @[someObject, @"Hello, World!", @42];