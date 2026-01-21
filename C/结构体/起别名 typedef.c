#include <stdio.h>

typedef struct student {
	char name[100];
	char gender;
	int age;
} S;	// 

int main() {
	S stu1 = {"zhangsan", 'M', 13};
	S stu2 = {"lisi", 'F', 14};
	S arr[2] = { stu1, stu2};
	
	for (int i = 0; i < 2; i++) {
		S temp = arr[i];
		printf("stu%d\nname%s gender%c age%d\n", i+1, temp.name, temp.gender, temp.age);
	}
	
	return 0;
}

