#include <stdio.h>
#include <stdlib.h> // 必须：提供 rand() 和 srand()
#include <time.h>   // 必须：提供 time()

// --- 通用封装函数 ---
// 作用：生成一个在 [min, max] 范围内的随机整数
// 包括 min，也包括 max
int get_random(int min, int max) {
    return rand() % (max - min + 1) + min;			// 多次调用。每次你需要一个新数字，就调用一次。
}

int main() {
    // 1. 播种 (Seeding)
    srand((unsigned int)time(NULL));			// 只调用一次。通常在程序刚启动时（main 函数开头）调用。

    // 2. 使用示例
    printf("生成 5 个 1 到 100 之间的随机数：\n");
    for (int i = 0; i < 5; i++) {
        // 直接调用封装好的函数
        int num = get_random(1, 100); 
        printf("%d ", num);
    }
    
    printf("\n");

    printf("生成一个 1000 到 9999 的随机验证码：\n");
    printf("%d\n", get_random(1000, 9999));

    return 0;
}
