#include <stdio.h>

struct fraction {
	char math[3];
	char English[3];
};

typedef struct student {
	char name[100];
	int age;
	char gender;
	struct fraction subject;
}S;

void method(S *p) {
	printf("accept result:\nname: %s, age: %d, gender: %c, math: %s, English: %s\nrevise information\n", (*p).name, (*p).age, (*p).gender, (*p).subject.math, (*p).subject.English);

	printf("name:");
	scanf("%s", (*p).name);
	printf("age:");
	scanf("%d", &(*p).age);
	printf("gender:");
	scanf(" %c", &(*p).gender);			// 使用 scanf 函数输入单个字符（%c）之前，如果输入缓冲区中可能留有前一次输入（特别是 int 型输入）所按下的 回车（换行符 \n），就需要在 %c 前加一个空格
	printf("math:");
	scanf("%s",(*p).subject.math);
	printf("English:");
	scanf("%s", (*p).subject.English);
}


int main() {
	
	S stu1 = {"0000", 0, '0', {"94","000"}};
	printf("initialise result: name: %s, age: %d, gender: %c, math: %s, English: %s\n", stu1.name, stu1.age, stu1.gender, stu1.subject.math, stu1.subject.English);
	
	// revise information
	method(&stu1);
	printf("revise result: name: %s, age: %d, gender: %c, math: %s, English: %s\n", stu1.name, stu1.age, stu1.gender, stu1.subject.math, stu1.subject.English);
	
	return 0;
}

