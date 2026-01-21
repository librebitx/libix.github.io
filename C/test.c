//输入n个整数，要求按由小到大的顺序输出
#include <stdio.h>

int min_arr(int *p,int len) {
    int temp = *p;
    for (int j = 0; j < len; j++) {
        if (*(p+j) < temp) {
            temp = *(p+j);      // 找出数组中最小的元素
        }
        //printf("temp = %d", *(p+j));
        // if (*(p+j) = temp) {
            
        //     if (j != 0) {
        //         printf("发现相同值：arr[%d] = %d\n", j, *(p+j));
        //         if ()
        //     }
        //     else {
        //         break;
        //     }
        // }
    }
    return temp;
}


int main() {
    int len;
// 确定数组元素个数
    printf("input number:");
    scanf("%d",&len);
    printf("len = %d\n", len);
// 依次输入元素
    int arr[len];
    // 声明一个变长数组，变长数组（VLA）不能在声明时初始化;
    // 使用变长数组时，必须先获得数组长度，再声明数组
    int min[len];
    for (int i = 0;i < len; i++) {
        printf("input no.%d:",i+1);
        scanf("%d",&arr[i]);

    }
// 检验
    printf("原数组：");
    printf("arr[%d] = { ", len);
    for (int m = 0; m < len; m++) {
        printf("%d ", arr[m]);
    }
    printf("}\n");    
    printf("minmum is : %d\n", min_arr(arr,len));


    int len2 = len;


    return 0;
}


































