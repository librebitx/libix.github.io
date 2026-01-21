#include <stdio.h>
#include <string.h>

struct message {
	char phonenumber[12];
	char mail[100];
};

struct student {
	char name[100];
	int age;
	struct message msg;
};

int main() {
	struct student stu;
	// 初始化 stu 变量
	strcpy(stu.name,"000");
	stu.age = 0;
	strcpy(stu.msg.phonenumber, "000");
	strcpy(stu.msg.mail,"000");
	printf("initialise stu result :\nname: %s\nage: %d\nphonenumber: %s\ne-mail: %s\n\n", stu.name, stu.age, stu.msg.phonenumber, stu.msg.mail);
	
	// 批量初始化
	struct student stu2 = {"111", 1, {"111", "111"}};
	printf("initialise stu2 result :\nname: %s\nage: %d\nphonenumber: %s\ne-mail: %s\n\n", stu2.name, stu2.age, stu2.msg.phonenumber, stu2.msg.mail);
	
	printf("Please enter student information\n");
	printf("name:");
	scanf("%s", stu.name);
	printf("age:");
	scanf("%d", &stu.age);
	printf("phonenumber:");
	scanf("%s", stu.msg.phonenumber);
	printf("e-mail:");
	scanf("%s", stu.msg.mail);
	
	printf("revise result :\nname: %s\nage: %d\nphonenumber: %s\ne-mail: %s", stu.name, stu.age, stu.msg.phonenumber, stu.msg.mail);
	return 0;
}

