# include <stdio.h>
# include <string.h>
typedef struct {
	char name[100];
	int age;
} S;

void method(S *p) {
	printf("revise start\nname:");
	scanf("%s",(*p).name);
	printf("age:");
	scanf("%d",&(*p).age);
}

int main() {
	S stu ;
	strcpy(stu.name,"000");
	stu.age = 12;
	printf("initialise result:\nname: %s\nage: %d", stu.name, stu.age);
	
	method(&stu);
	printf("revise result:\nname: %s\nage: %d", stu.name, stu.age);
		
	return 0;
}



