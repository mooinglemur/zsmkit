all:
	mkdir -p ./obj
	ca65 -t cx16 -o ./obj/zsmckit.o ./src/zsmckit.s
	cl65 -t cx16 -m cdemo.map -Ln cdemo.sym -o CDEMO.PRG ./src/cdemo.c ./obj/zsmckit.o
clean:
	rm -rf CDEMO.PRG ./obj/zsmckit.o cdemo.map cdemo.sym
