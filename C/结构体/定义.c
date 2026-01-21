# include <stdio.h>
struct student {
	char name[100];
	int age;
	char gender;
	float weight;
};

int main() {
	struct student stu1 = {"zhangsan", 13, 'M', 70.25};
	struct student stu2 = {"lisi", 14, 'F', 45.65};
	
	struct student arr[] = {stu1, stu2};
	
	printf("result:\n");
	
	for (int i = 0; i < 2; i++) {
		struct student temp = arr[i];
		printf("stu%d\nname: %s\nage: %d\ngender: %c\nweight: %.2f\n", i+1, temp.name, temp.age, temp.gender, temp.weight);
	}
	return 0;
}
