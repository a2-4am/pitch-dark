Source: http://infodoc.plover.net/hints/

These help files were put together by Digby McWiggle and Steven Marsh as part of their PRIZM project, whose website is now defunct. They are a compilation of all the Invisiclues available for each of the games in one handy cross-platform file.

Small patches were applied to each file to remove the warning that your screen is too small and you should make it wider if possible. Since this is not possible on the Apple II (and 80 columns is still too small), the subroutine responsible for this warning has been changed to immediately return without printing anything or waiting for a key. Here is the command I used, which finds the byte sequence "10 00 21 12 0d 01 00 0d 02 01" and replaces the first byte with B0, the "return true" opcode.

for f in *.z5; do
  xxd -p -c 256 "$f" | \
    tr -d '\n' | \
    sed "s/100021120d01000d0201/B00021120d01000d0201/g" | \
    xxd -r -p \
    > ../patched/"$f"
done

-4am

last modified: 2018-03-12
