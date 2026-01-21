#include <stdio.h>
#include <string.h>

typedef struct student {
	char name[100];
	int age;
} S;

// 通过指针传递结构体
// 如果使用按值传递， 函数修改的是结构体副本，对函数外部（main 函数）的原始 stu 变量没有任何影响。

void method(S *p) {			// p 指向变量 stu，所以 *p 相当于整个 stu 变量本身；
	printf("revise name: ");
	scanf("%s", (*p).name);
	printf("revise age: ");
	scanf("%d",&(*p).age);
}

int main() {

	S stu;

	strcpy(stu.name, "000");			// strcpy (String Copy) 函数用于将一个字符串（源字符串）的内容完整地复制到另一个字符串（目标字符串）中，包括字符串末尾的空字符 \0。
	stu.age = 0;
	printf("initialise result: name is %s, age is %d.\n", stu.name, stu.age);
	
	method(&stu);
	printf("revise result: name is %s, age is %d.\n", stu.name, stu.age);

	return 0;
}

