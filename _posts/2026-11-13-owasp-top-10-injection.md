---
title: "[미션] OWASP Top 10 보안 동향 분석"
date: 2026-11-13 21:00:00 +0900
categories: ["블로그/기술문서"]
description: "OWASP Top 10의 Injection을 공부하며 SQL Injection과 XSS를 정리했다."
---

## 미션 목표

OWASP Top 10 보안 동향을 조사하여, 자신만의 언어로 블로그에 정리한다.

## 수행 과정

1. OWASP Top 10 주제 중에서 관심 있는 주제를 하나 선택한다.
2. 해당 주제에 대해서 최소 5개 이상의 자료를 참고하여 내용을 공부한다.
3. 공부한 내용을 자신만의 언어로 블로그에 정리한다.

---

## OWASP TOP 10이란?

OWASP Top 10은 웹사이트나 웹 서비스에서 특히 주의해야 할 보안 위험을 10가지 유형으로 정리한 가이드이다.

### Top 10:2025 List

1. [A01:2025 - Broken Access Control](https://top10.owasp.org/2025/A01_2025-Broken_Access_Control/)
2. [A02:2025 - Security Misconfiguration](https://top10.owasp.org/2025/A02_2025-Security_Misconfiguration/)
3. [A03:2025 - Software Supply Chain Failures](https://top10.owasp.org/2025/A03_2025-Software_Supply_Chain_Failures/)
4. [A04:2025 - Cryptographic Failures](https://top10.owasp.org/2025/A04_2025-Cryptographic_Failures/)
5. [A05:2025 - Injection](https://top10.owasp.org/2025/A05_2025-Injection/)
6. [A06:2025 - Insecure Design](https://top10.owasp.org/2025/A06_2025-Insecure_Design/)
7. [A07:2025 - Authentication Failures](https://top10.owasp.org/2025/A07_2025-Authentication_Failures/)
8. [A08:2025 - Software or Data Integrity Failures](https://top10.owasp.org/2025/A08_2025-Software_or_Data_Integrity_Failures/)
9. [A09:2025 - Security Logging and Alerting Failures](https://top10.owasp.org/2025/A09_2025-Security_Logging_and_Alerting_Failures/)
10. [A10:2025 - Mishandling of Exceptional Conditions](https://top10.owasp.org/2025/A10_2025-Mishandling_of_Exceptional_Conditions/)

이 중에 가장 관심있는 부분은 **A05:2025 - Injection**이다.

## 참고자료

1. [A05 Injection - OWASP Top 10:2025](https://top10.owasp.org/2025/A05_2025-Injection/)
2. [SQL 삽입 | SQL 삽입이란? | Cloudflare](https://www.cloudflare.com/ko-kr/learning/security/threats/sql-injection/)
3. [Cross-Site Scripting (XSS) | Learn | Dreamhack](https://dreamhack.io/lecture/units/webhacking-xss)
4. [SQL Injection | Learn | Dreamhack](https://dreamhack.io/lecture/units/webhacking-sql-injection)
5. [SQL Injection Prevention - OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
6. [Cross Site Scripting Prevention - OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)

공부 순서는 Injection이 뭔지에 대해 공부해보고 드림핵을 통해 대표적인 Injection 공격(Sql injection, XSS)을 공부하고 문제를 풀어본다. 그 뒤 Sql injection과 XSS 방어기법을 공부해봤다.

## 1. Injection이 무엇인가

Injection은 프로그램이 신뢰할 수 없는 사용자의 입력을 브라우저, 데이터베이스, 쉘 등에 전달하는 과정에서 입력의 일부를 명령으로 실행하게 되는 취약점이다.

### Injection에 취약한 경우

- 애플리케이션이 사용자의 입력을 검증하거나 필터링 하지 않았을때
- 매개변수화하지 않은 호출을, 해당 문맥에 맞는 이스케이프 처리 없이 해석기에 직접 전달한다.

Injection에 흔한 유형으로는 Sql, NoSql, Xss, Os command, LDAP 등이 있다.

나는 이 중에 Sql과 Xss를 공부해보겠다.

## 2. SQL Injection

일단 SQL이 뭐냐.

SQL은 데이터베이스에 정보를 요청하거나 저장하고 수정할 때 사용하는 언어이다.

SQL 인젝션은 웹사이트 입력창에 SQL 명령을 넣어서 데이터베이스가 원래 하려던 일과 다른 동작을 하게 만드는 공격이다. 웹사이트가 입력값을 제대로 구분하지 않고 SQL 문에 그대로 붙여 넣을 때 문제가 생긴다. 사용자가 적은 내용을 그냥 글자로 다루지 않고 데이터베이스 명령어로 실행해 버리는 거다.

```sql
SELECT * FROM accounts WHERE user_id='user' and user_pw='user'
```

이런 쿼리가 있다고 하자.

SELECT는 조회 명령어, *은 모든걸 확인하자, FROM accounts는 accounts 테이블에서 조회하자이다.

여기서 user_id가 ‘user’이고 user_pw가 ‘user’인 아이디 정보를 찾을려고 한다.

```py
userid = request.form.get('userid')
userpassword = request.form.get('userpassword')
res = query_db(f'select * from users where userid="{userid}" and userpassword="{userpassword}"')
```

이런 코드가 있다고 하자. 이 코드를 보면 userid와 userpassword를 그 어떤 검증 및 필터링 없이 그대로 db에 넣어서 찾는것을 볼 수 있다.

만약에 여기서 userid에 입력을 admin” —이라고 넣으면 어떻게 될까?

users의 테이블에 admin이라는 id를 가지는데 그 뒤 userpassword 뒤는 —(주석)로 주석처리가 되었다. 그러므로 비밀번호 없이 admin의 계정에 접근할 수 있게 되는 것이다. 이것이 기본적인 sql injection이다.

여기서 추가적으로 하나만 더 보자.

## 2-1. Blind SQL Injection

위에서 했던 SQL Injection은 비밀번호를 몰라도 로그인이 되는 방법이였다면 Blind sql injection은 비밀번호를 참, 거짓 질문을 반복하고 사이트 응답을 통해 알아낼 수 있다.

```sql
SELECT * FROM accounts WHERE user_id='admin' and substr(user_pw,1,1)='a'-- ' and user_pw='';
```

여기서 substr이 뭐냐.

```sql
substr(string, position, length)
substr('ABCD', 1, 1) = 'A'
substr('ABCD', 2, 2) = 'BC'
// SQL에서는 = 가 비교 연산자이다.
```

substr은 지정한 위치부터 길이까지의 값들을 가지고 온다.

이를 통해 비밀번호도 알아낼 수가 있다.

## 3. XSS(Cross-Site-Scripting)

XSS는 웹사이트에 입력한 글이 그냥 글자로 보이는 게 아니라, 브라우저에서 코드로 실행되는 취약점이다. 예를 들어 게시글이나 댓글에 악성 코드를 넣었는데 사이트가 입력값을 제대로 처리하지 않으면, 그 페이지를 보는 사람의 브라우저에서 코드가 실행될 수 있다.

XSS 공격에서 주로 사용되는 것은 자바스크립트이다.

자바스크립트는 웹 문서의 동작을 구현할 수 있기에 세션 및 쿠키 같은것도 얻을 수 있다.

## 3-1. Stored XSS

Stored XSS는 코드가 게시글이나 댓글처럼 사이트에 저장됐다가, 다른 사람이 그 페이지를 볼 때 실행되는 XSS다. 예를 들어 댓글에 코드를 넣었는데 사이트가 이를 안전하게 처리하지 않고 저장하면, 그 댓글을 보는 사람들의 브라우저에서 코드가 실행될 수 있다.

## 3-2. Reflected XSS

Reflected XSS는 사용자가 보낸 입력값이 서버에 저장되지는 않지만, 서버 응답에 그대로 포함되어 브라우저에서 코드로 실행되는 XSS다. 예를 들어 검색창에 입력한 내용이 검색 결과 페이지에 그대로 표시될 때, 입력값을 안전하게 처리하지 않으면 악성 코드가 실행될 수 있다. Reflected XSS는 보통 피해자가 직접 코드를 입력하는 게 아니라, 공격자가 악성 입력이 들어 있는 링크를 만들어 보내고 피해자가 그 링크를 누르는 방식으로도 발생된다.

## 3-3. DOM-based XSS

Reflected XSS는 DOM-based XSS랑 비슷하다. 둘 다 조작된 입력이 브라우저에서 실행된다는 점이 같다. 차이는 어떻게 처리되냐이다. Reflected XSS는 입력값이 서버로 갔다가 응답 페이지에 다시 담겨 오면서 실행되고, DOM-based XSS는 서버 응답과는 별개로 브라우저의 자바스크립트가 주소에 있는 값을 화면에 넣다가 실행된다.

## 3-4. Universal XSS

Universal XSS는 웹사이트의 입력값 처리 실수로 생기는 일반 XSS랑 다르다. 브라우저 자체나 브라우저 확장 프로그램의 취약점을 이용해, 원래는 접근할 수 없어야 하는 사이트의 정보에 접근하거나 코드를 실행하는 공격이다. 일반 XSS가 특정 웹사이트의 문제라면, Universal XSS는 브라우저의 보안 문제라고 볼 수 있다.

## 4. 입력값이 명령으로 실행되지 않게 하려면

사용자의 입력값이 명령어로 실행되지 않도록 해야 한다.

로그인할 때 아이디와 비밀번호를 SQL 문에 그대로 붙여 넣으면, 입력한 내용이 데이터가 아니라 SQL 명령으로 해석될 수 있다. 그래서 SQL 문과 사용자가 입력한 값을 따로 전달하는 **매개변수화 쿼리**나 ORM 같은 안전한 도구를 사용하는 것이 가장 좋다.

XSS는 사용자가 입력한 내용이 웹페이지에서 코드로 실행되지 않도록 해야 한다. 입력한 내용을 화면에 보여줄 때는 HTML이 아니라 일반 글자로 처리해야 한다.

부득이하게 입력값을 직접 처리해야 한다면, 허용할 값을 미리 정해 검증하고 상황에 맞게 특수문자를 처리할 수 있다. 다만 이 방법만으로 완전히 방어하기는 어렵기 때문에, SQL 문과 입력값을 분리하고 화면에 입력값을 안전하게 표시하는 방법을 우선으로 사용해야 한다.