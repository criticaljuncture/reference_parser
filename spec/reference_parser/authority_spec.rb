require "spec_helper"

AUTHORITY_SCENARIOS = [
  {expect: "DIRECTIVE 1/1982-06-25", ex: "Information Security Oversight Directive No. 1, June 25, 1982"},
  {expect: "DETERMINATION 23/2003, DIRECTIVE 42/2026-01-07, EO 123456, MEMORANDUM 2026-01-01, NOTICE 2026-01-02, RP 42/2026, STAT 12/345, STAT 12/678, USC 11/22", ex: "Lorem; Presidential Determination 2003-23, National Security Decision Directive 42, “Lorem Ipsum,” signed by the President on January 7, 2026 ; E.O. 123456;, Presidential Memorandum of Jan. 1, 2026; and Notice of January 2, 2026; Reorganization Plan No. 42 of 2026, sec. 1; 12 Stat. 345, 678; 11 U.S.C. 22., Ipsum"},
  {expect: "EO 10865, EO 12333, EO 12829, EO 12866, EO 12968, EO 13526, EO 13563, EO 13587, EO 13691, PUBL 108/458, USC 42/2011 et seq, USC 50/44, USC 50/3501 et seq", ex: "32 CFR part 2004; E.O. 10865; E.O. 12333; E.O. 12829; E.O. 12866; E.O. 12968; E.O. 13526; E.O. 13563; E.O. 13587; E.O. 13691; Public Law 108-458; Title 42 U.S.C. 2011 et seq.; Title 50 U.S.C. Chapter 44; Title 50 U.S.C. 3501 et seq."},
  {expect: "EO 11034, EO 12048", ex: "E.O. 11034 and 12048"},
  {expect: "PUBL 81/193, USC 10/2574, USC 10/4308, USC 10/4506, USC 10/4507, USC 10/4627, USC 10/4655, PUBL 92/249", ex: "Pub. L. 81-193; 10 U.S.C. secs. 2574, 4308, 4506, 4507, 4627, and 4655, and Pub. L. 92-249."},
  {expect: "PUBL 87/195, STAT 75/445, USC 22/2381, EO 12163, FR 44/56673", ex: "(Section 621 of Public Law. 87-195, 75 Stat. 445, (Section 2381 of Title 22 of the U.S.C.), as amended; E.O. 12163, Sept. 29, 1979, 44 Federal Register 56673; and Title 3 of the CFR, 1979 Comp., p. 435)"},
  {expect: "PUBL 93/303, STAT 86/461, RP 3/1950, STAT 64/1262", ex: "Sec. 4, Land and Water Conservation Fund Act of 1965 (16 U.S.C.A. 4601-6a (Supp., 1974)), as amended by Pub. L. 93-303; and sec. 3, Act of July 11, 1972, 86 Stat. 461; sec. 2 of Reorganization Plan No. 3 of 1950 (64 Stat. 1262)."},
  {expect: "PUBL 101/576, STAT 104/2838", ex: "Pub. L. 101-576, 104 Stat. 2838;"},
  {expect: "PUBL 110/53, STAT 121/266", ex: "; Pub. L. 110-53 (121 Stat. 266, Aug. 3, 2007)."},
  {expect: "PUBL 111/211, STAT 124/2282, USC 42/2996f(b)(2), USC 42/2996g(e)", ex: "Sec. 234(d), Public Law 111-211, 124. Stat. 2282; 42 U.S.C. 2996f(b)(2); 42 U.S.C. 2996g(e)."},
  {expect: "PUBL 112/141, STAT 126/707, USC 49/5326, PUBL 112/141, STAT 126/718", ex: "Sec. 20019 of Pub. L. 112-141, 126 Stat. 707, 49 U.S.C. 5326; Sec. 20025(a) of Pub. L. 112-141, 126 Stat, 718, 49 CFR 1.91."},
  {expect: "RP 21/1950, STAT 64/1273, RP 7/1961, STAT 75/840, PUBL 91/469, STAT 84/1036", ex: "Reorganization Plans No. 21 of 1950 (64 Stat. 1273), No. 7 of 1961 (75 Stat. 840) as amended by Pub. L. 91-469 (84 Stat. 1036)"},
  {expect: "USC 7/4a(j), USC 7/16a, PUBL 97/444, STAT 96/2294, USC 5/552, USC 5/552a, USC 5/552b", ex: "Section 145.8 is also issued under 7 U.S.C. 4a(j) and 16a as amended by Pub. L. 97-444, 96 Stat. 2294 (1983), and 5 U.S.C. 552, 552a and 552b."},
  {expect: "STAT 38/719, STAT 38/721", ex: "Secs. 5, 6, 38 Stat. 719 as amended, 721"},
  {expect: "STAT 42/1518, STAT 68A/580", ex: "Interpret or apply sec. 6, 42 Stat. 1518, as amended, sec. 4854, 68A Stat. 580;"},
  {expect: "STAT 44/1355, USC 7/494", ex: "Sec. 3, 44, Stat. 1355, as amended; 7 U.S.C. 494."},
  {expect: "STAT 45/401, STAT 54/670", ex: "45 Stat. 401, 54 Stat. 670;"},
  {expect: "STAT 48/1066, STAT 48/1068, STAT 48/1082", ex: "Secs. 4, 5, 303, 48 Stat., as amended, 1066, 1068, 1082;"},
  {expect: "STAT 49/164, STAT 49/1148", ex: "Sec. 4, 49 Stat. 164, secs. 7-17, 49 Stat. 1148, as amended;"},
  {expect: "STAT 49/1987, STAT 49/1988, USC 46/1114, USC 46/1117, STAT 49/2011, USC 46/1211", ex: "Secs. 204, 207, 49 Stat. 1987, as amended, 1988, as amended; 46 U.S.C. 1114, 1117; sec. 801, 49 Stat. 2011, 46 U.S.C. 1211."},
  {expect: "STAT 52/65, STAT 52/66, USC 7/1372, USC 7/1375", ex: "Secs. 372, 375, 52 Stat. 65, as amended, 66, as amended; 7 U.S.C. 1372, 1375."},
  {expect: "STAT 54/1234, USC 5/Appendix II", ex: "54 Stat. 1234 (5 U.S.C. App. II);"},
  {expect: "STAT 58/690, STAT 77/400, USC 42/216, USC 42/1857g, STAT 58/691, STAT 58/707, STAT 62/464, STAT 62/598, STAT 64/444, STAT 74/364, STAT 76/1073, STAT 77/394, STAT 77/395, STAT 79/1062, USC 42/241, USC 42/282, USC 42/287a, USC 42/288a, USC 42/289c, USC 42/242f, USC 42/289g, USC 42/1857b, USC 42/280b-4, USC 42/280b-5", ex: "Sec. 215, 58 Stat. 690, as amended, sec. 8, 77 Stat. 400; 42 U.S.C. 216, 1857g; secs. 301, 402, 58 Stat. 691, as amended, 707, secs. 412, 422, 62 Stat. 464, 598, sec. 433, 64 Stat. 444, as amended, sec. 308, 74 Stat. 364, sec. 444, 76 Stat. 1073, sec. 3, 77 Stat. 394, secs. 394, 395, 79 Stat. 1062; 42 U.S.C. 241, 282, 287a, 288a, 289c, 242f, 289g, 1857b, 280b-4, 280b-5."},
  {expect: "STAT 66/173, STAT 66/195, STAT 66/197, STAT 66/201, STAT 66/203, STAT 66/212, STAT 66/219, STAT 66/221-223, STAT 66/226, STAT 66/227, STAT 66/230", ex: "66 Stat. 173, 195, 197, 201, 203, 212, 219, 221-223, 226, 227, 230;"},
  {expect: "STAT 78/252, USC 42/2000d-1", ex: "Sec. 602, 78 Stat. 252; 42 U.S.C. 2000d-1; sec. 15.9(d) of subpart A to 7 CFR, part 15, and laws referred to in the appendix to subpart A, part 15, title 7 CFR."},
  {expect: "STAT 90/2958, USC 16/472a, STAT 98/2213, USC 16/618, STAT 104/714-726, USC 16/620-620j, USC 25/3055, USC 25/3057, STAT 113/1501a, USC 16/528 note", ex: "90 Stat. 2958, 16 U.S.C. 472a; 98 Stat. 2213, 16 U.S.C. 618, 104 Stat. 714-726, 16 U.S.C. 620-620j, 25 U.S.C. 3055 and 3057, 113 Stat. 1501a, 16 U.S.C. 528 note; unless otherwise noted."},
  {expect: "STAT 92/865 et seq", ex: "92 Stat. 865 et seq.;"},
  {expect: "STAT 104/2838", ex: "104 Stat. 2838;"},
  {expect: "USC 5/Appendix 3", ex: "5 U.S.C. ap3;"},
  {expect: "USC 5/Appendix 534", ex: "5 U.S.C. App. P. 534."},
  {expect: "USC 5/1103(c), USC 5/2301, USC 5/2302, USC 5/4101 et seq, EO 11348, EO 11478, EO 13087, EO 13152", ex: "5 U.S.C. 1103(c), 2301, 2302, 4101, et seq.; E.O. 11348, 3 CFR, 1967 Comp., p. 275, E.O. 11478, 3 CFR 1966-1970 Comp., page 803, unless otherwise noted, E.O. 13087; and E.O. 13152."},
  {expect: "USC 5/1103(c)(2)(C), USC 5/3396, USC 5/3397, USC 5/4101 et seq", ex: "5 U.S.C. 1103 (c)(2)(C), 3396, 3397, 4101 et seq."},
  {expect: "USC 5/1204, USC 5/1221, USC 5/2302(b)(8), USC 5/2302(b)(9)(A)(i), USC 5/2302(b)(9)(B), USC 5/2302(b)(9)(C), USC 5/2302(b)(9)(D), USC 5/7701", ex: "5 U.S.C. 1204, 1221, 2302(b)(8) and (b)(9)(A)(i), (B), (C), or (D), and 7701."},
  {expect: "USC 5/301, USC 13/301-307, RP 5/1990, PUBL 107/228, STAT 116/1350", ex: "5 U.S.C. 301; 13 U.S.C. 301-307; Reorganization plan No. 5 of 1990 (3 CFR 1949-1953 Comp., p.1004); Department of Commerce Organization Order No. 35-2A, July 22, 1987, as amended and No. 35-2B, December 20, 1996, as amended; Public Law 107-228, 116 Stat. 1350."},
  {expect: "USC 5/301, USC 25/2, USC 25/9, USC 25/2710", ex: "5 U.S.C. 301; 25 U.S.C. sections 2,9 and 2710."},
  {expect: "USC 5/301, USC 5/8137, USC 5/8145, USC 5/8149, RP 2/1946,", ex: "5 U.S.C. 301, 8137, 8145 and 8149; 1946 Reorganization Plan No. 2, sec. 3, 3 CFR 1943-1948 Comp., p. 1064"},
  {expect: "USC 5/3101 note, USC 5/3301, USC 5/3131 et seq, USC 5/3302", ex: "5 U.S.C. 3101 note, 3301, 3131 et seq. 3302;"},
  {expect: "USC 5/43, USC 5/5307(d)", ex: "5 U.S.C. chapter 43 and 5307(d)."},
  {expect: "USC 5/504", ex: "Section 504, Title 5 U.S.C."},
  {expect: "USC 5/5514, EO 11609, EO 12197, USC 7/4a(j)", ex: "5 U.S.C. 5514, E.O. 11609 (redesignated E.O. 12197), 5 CFR part 550, subpart K, and 7 U.S.C. 4a(j), unless otherwise noted."},
  {expect: "USC 5/552 note", ex: "5 U.S.C. 552 note"},
  {expect: "USC 5/552, RP 3/1978, EO 12127, EO 12148, EO 12241, DIRECTIVE 1979-12-07", ex: "5 U.S.C. 552, Reorganization Plan No. 3 of 1978, E.O. 12127, E.O. 12148, E.O. 12241; Presidential Directive of Dec. 7, 1979."},
  {expect: "USC 5/552, USC 12/248(i), USC 12/248(k), USC 12/321 et seq, USC 12/611 et seq, USC 12/1442", ex: "5 U.S.C. 552; 12 U.S.C. 248(i) and (k), 321 et seq., 611 et seq., 1442"},
  {expect: "USC 5/552a, USC 5/552 note", ex: "5 U.S.C. 552a and 552 note", expected_authority: {section: "552 note"}},
  {expect: "USC 5/552b", ex: "Government in the Sunshine Act, sec. 552b of title 5, U.S.C.;"},
  {expect: "USC 5/553, USC 5/559", ex: "5.U.S.C. 553 and 559;"},
  {expect: "USC 5/3401 note, USC 5/3402", ex: "5 U.S.C. 3401 (note and 3402)."},
  {expect: "USC 5/6133(a), USC 5/6129, USC 5/6303(e), USC 5/6303(f), USC 5/6304(d)(2), USC 5/6306(b), USC 5/6308(a), USC 5/6311", ex: "Subparts A through E issued under 5 U.S.C. 6133(a) (read with 5 U.S.C. 6129), 6303(e) and (f), 6304(d)(2), 6306(b), 6308(a) and 6311;"},
  {expect: "USC 5/6133(a), USC 5/6129, USC 5/6326(b)", ex: "issued under 5 U.S.C. 6133(a) (read with 5 U.S.C. 6129) and 6326(b)"},
  {expect: "USC 5/7321 et seq, USC 5/Appendix 3", ex: "5 U.S.C. 7321 et seq. and app. 3."},
  {expect: "USC 5/8332(b)(17), USC 5/8411(b)(6)", ex: "5 U.S.C. 8332(b)(17) and 8411(b)(6)"},
  {expect: "USC 5/8351, USC 5/8432(a), USC 5/8432(b), USC 5/8432(c), USC 5/8432(j), USC 5/8432d, USC 5/8474(b)(5), USC 5/8474(c)(1), USC 5/8440e", ex: "5 U.S.C. 8351, 8432(a), 8432(b), 8432(c), 8432(j), 8432d, 8474(b)(5) and (c)(1), and 8440e."},
  {expect: "USC 5/8508, FR 40/18515, USC 5/301, USC 5/8501-8508", ex: "5 U.S.C. 8508; Secretary's Order No. 4-75, 40 FR 18515; (5 U.S.C. 301). Interpret and apply secs. 8501-8508 of title 5, United States Code."},
  {expect: "USC 5/Appendix 1", ex: "5 U.S.C., App. 1."},
  {expect: "USC 5/Appendix 3", ex: "5 U.S.C. Appendix 3."},
  {expect: "USC 5/Appendix", ex: "5 U.S.C. Appendix."},
  {expect: "USC 6/218, USC 6/218 note", ex: "6 U.S.C. 218 and note;"},
  {expect: "USC 7/1308, USC 7/1308-1, USC 7/1308-2, USC 7/1308-3, USC 7/1308-3a, USC 7/1308-4, USC 7/1308-5, PUBL 115/123", ex: "7 U.S.C. 1308, 1308-1, 1308-2, 1308-3, 1308-3a, 1308-4, and 1308-5; and Title I, Pub. L. 115-123."},
  {expect: "USC 8/1101, USC 8/1101 note, USC 8/1103, USC 8/1182, USC 8/1183, USC 8/1185, EO 13323, FR 69/241, USC 8/1185 note, USC 8/1201, USC 8/1224, USC 8/1225, USC 8/1226, USC 8/1228, USC 8/1357, USC 8/1365a, USC 8/1365a note, USC 8/1365b, USC 8/1379, USC 8/1731", ex: "8 U.S.C. 1101 and note, 1103, 11f58, 1182, 1183, 1185 (pursuant to Executive Order 13323, 69 FR 241, 3 CFR, 2003 Comp., p. 278), 1185 note, 1201, 1224, 1225, 1226, 1228, 1357, 1365a and note, 1365b, 1379, 1731-32;"},
  {expect: "USC 12/1811, USC 12/1815, USC 12/1816, USC 12/1817, USC 12/1818, USC 12/1819(a), USC 12/1820(g), USC 12/1831o-1, USC 12/3108, USC 12/3207", ex: "12 U.S.C. 1811, 1815, 1816, 1817, 1818, 1819(a) (Seventh) and (Tenth), 1820(g), 1831o-1, 3108, 3207."},
  {expect: "USC 12/1815(a), USC 12/1819(Tenth), USC 12/1831o, USC 12/5412", ex: "12 U.S.C. 1815(a), 1819(Tenth), 1831o, 5412;"},
  {expect: "USC 12/2002, USC 12/2279a-2279a-3, USC 12/2279b-2279f-1, USC 12/2279aa-5(e)", ex: "12 U.S.C. 2002, 2279a-2279a-3, 2279b-2279f-1, 2279aa-5(e)"},
  {expect: "USC 12/5511, USC 12/5512, USC 12/5514(b), USC 12/5531(b), USC 12/5532", ex: "12 U.S.C. 5511, 5512, 5514(b), 5531(b), (c), and (d), 5532."},
  {expect: "USC 15/77e, USC 15/78 mm, USC 15/80a-8, USC 15/80a-9, USC 15/80a-20, USC 15/80b-11, USC 15/7201 et seq", ex: "15 U.S.C. 77e, 78 mm, 80a-8, 80a-9, 80a-20, 80b-11 and 7201 et seq.;"},
  {expect: "USC 16/1531, USC 16/1543", ex: "16 U.S.C. 1531 1543"},
  {expect: "USC 16/1861a(b), USC 46/Appendix 53735, PUBL 106/554", ex: "16 U.S.C. 1861a(b) through (e), 46 App. U.S.C. 53735, section 144(d) of Division B of Pub. L. 106-554"},
  {expect: "USC 16/2103(d), USC 16/2109(e)", ex: "16 U.S.C. 2103(d) & 2109(e)."},
  {expect: "USC 16/470aaa et seq, USC 16/670 et seq, USC 16/877 et seq, USC 16/1241 et seq, USC 16/1281c, USC 43/315a, USC 43/1701 et seq", ex: "16 U.S.C. 470aaa, et seq.; 670, et seq.; 877, et seq.; 1241, et seq.; and 1281c; and 43 U.S.C. 315a and 1701 et seq."},
  {expect: "USC 18/3621, USC 18/3622, USC 18/3524, USC 18/4001, USC 18/4005, USC 18/4042, USC 18/4045, USC 18/4081, USC 18/4082, USC 18/313, USC 18/5006-5024, USC 18/5039", ex: "18 U.S.C. 3621, 3622, 3524, 4001, 4005, 4042, 4045, 4081, 4082 (Repealed in part as to offenses committed on or after November 1, 1987), Chapter 313, 5006-5024 (Repealed October 12, 1984 as to offenses committed after that date), 5039;"},
  {expect: "USC 19/1202, PUBL 107/43, STAT 115/243, USC 19/2112 note", ex: "Sections 10.701 through 10.712 also issued under 19 U.S.C. 1202 (General Note 18, HTSUS) and Pub. L. 107-43, 115 Stat. 243 (19 U.S.C. 2112 note)."},
  {expect: "USC 19/1313(e), USC 19/1313(i), PUBL 106/476, STAT 114/2101, USC 19/1434, USC 19/1435", ex: "Sections 10.80, 10.81, 10.82, 10.83 also issued under 19 U.S.C. 1313 (e) and (i);\nSection 10.91 also issued under Pub. L. 106-476 (114 Stat. 2101), sections 1434, 1435;"},
  {expect: "USC 19/66, USC 19/1202, USC 19/1321, USC 19/1481", ex: "19 U.S.C. 66, 1202 (General Note 3(i), Harmonized Tariff Schedule of the United States (HTSUS)), 1321, 1481."},
  {expect: "USC 19/66, USC 19/1202, USC 19/1624", ex: "19 U.S.C. 66, 1202 (General Note 3(i)), Harmonized Tariff Schedule of the United States, 1624."},
  {expect: "USC 16/668a-d, USC 16/703-712, USC 16/742a-j-l, USC 16/1361-1384, USC 16/1401-1407, USC 16/1531-1543, USC 16/3371-3378, USC 18/42, USC 19/1202", ex: "16 U.S.C. 668a-d, 703-712, 742a-j-l, 1361-1384, 1401-1407, 1531-1543, 3371-3378; 18 U.S.C. 42; 19 U.S.C. 1202."},
  {expect: "USC 20/1091, USC 50/Appendix 462", ex: "(Authority: 20 U.S.C. 1091 and 50 App. 462)"},
  {expect: "USC 20/1681-1686, USC 29/794, USC 42/2000d-2000d-7, USC 42/3601-3631, USC 42/5891, USC 42/6101-6107, USC 42/7101 et seq", ex: "20 U.S.C. 1681-1686; 29 U.S.C. 794; 42 U.S.C. 2000d to 2000d-7, 3601-3631, 5891, 6101-6107, 7101 et seq."},
  {expect: "USC 22/211a, USC 22/212, USC 22/212a, USC 22/212b, USC 22/213, USC 22/213n, PUBL 106/113, STAT 113/1536, STAT 113/1501, USC 22/214, USC 22/214a, USC 22/217a", ex: "22 U.S.C. 211a, 212, 212a, 212b, 213, 213n (Pub. L. 106-113 Div. B, Sec. 1000(a)(7) [Div. A, Title II, Sec. 236], 113 Stat. 1536, 1501A-430); 214, 214a, 217a"},
  {expect: "USC 25/473a, USC 25/476, USC 25/477, USC 25/503", ex: "25 U.S.C. 473a, 476, 477, as amended, and 503."},
  {expect: "USC 25/2011, USC 25/2015, STAT 92/2322, STAT 92/2327", ex: "25 U.S.C. 2011 and 2015, Secs. 1131 and 1135 of the Act of November 1, 1978, 92 Stat. 2322 and 2327;"},
  {expect: "USC 30/901 et seq", ex: "30 U.S.C. 901 et seq."},
  {expect: "USC 31/501-06", ex: "31 U.S.C. 501-06."},
  {expect: "USC 31/5311-5314, USC 31/5316-5332.2", ex: "31 U.S.C. 5311-5314, 5316-5332.2."},
  {expect: "USC 34/101, USC 34/10110, USC 34/10221(a), USC 34/10225, USC 34/10226, USC 34/10251(a), USC 34/10261(a)(4), USC 34/10261(b), USC 34/10272, USC 34/110286, USC 34/10287, USC 34/10288", ex: "34 U.S.C. ch. 101, subch. XI; 34 U.S.C. 10110, 10221(a), 10225, 10226, 10251(a), 10261(a)(4) & (b), 10272, 110286, 10287, 10288;"},
  {expect: "USC 39/401, USC 39/2601, USC 39/5604", ex: "39 U.S.C. 401, 2601 Chap. 56 Section 5604"},
  {expect: "USC 40/101, USC 40/541 et seq, USC 40/701", ex: "40 U.S.C. subtitle I and sections 101, 541 et seq., and 701;"},
  {expect: "USC 40/318-318d, USC 40/486", ex: "40 U.S.C. 318-318d. 486"},
  {expect: "USC 42/300j-9(i), USC 42/5851, USC 42/6971, USC 42/7622, USC 42/9610", ex: "42 U.S.C. 300j-9(i)BVG, 5851, 6971, 7622, 9610;"},
  {expect: "USC 42/2000e-12, USC 42/2000e-16c, USC 42/2000ff-6(b), USC 42/2000gg-2(d)", ex: "42 U.S.C. 2000e-12 and-16c; 42 U.S.C. 2000ff-6(b); 42 U.S.C. 2000gg-2(d)."},
  {expect: "USC 42/2000e-12(a), USC 5/552, PUBL 93/502, PUBL 99/570, PUBL 105/231, USC 31/9701", ex: "42 U.S.C. 2000e-12(a), 5 U.S.C. 552 as amended by Pub. L. 93-502, Pub. L. 99-570, and Pub. L. 105-231; for § 1610.15, nonsearch or copy portions are issued under 31 U.S.C. 9701."},
  {expect: "USC 42/3535(d), USC 42/1437a, USC 42/1437c, USC 42/1437f, USC 42/1437", ex: "Sec. 7(d), Dept. of HUD Act (42 U.S.C. 3535(d)); secs. 3(6), 5(b), 8, 11(b) of the U.S. Housing Act of 1937 (42 U.S.C. 1437a, 1437c, 1437f, and 1437)."},
  {expect: "USC 42/402, USC 42/405(a)-(b), USC 42/405(d)-(h), USC 42/416(i), USC 42/421(a), USC 42/421(h)-(j), USC 42/422(c), USC 42/423, USC 42/425, USC 42/902(a)(5), USC 42/1320e-3", ex: "42 U.S.C. 402, 405(a)-(b) and (d)-(h), 416(i), 421(a) and (h)-(j), 422(c), 423, 425, 902(a)(5), and 1320e-3;"},
  {expect: "USC 42/421(m), USC 42/902(a)(5), USC 42/1382, USC 42/1382c, USC 42/1382h, USC 42/1383, USC 42/1383b, STAT 98/1794, STAT 98/1801, STAT 98/1802, STAT 98/1808, USC 42/421 note, USC 42/423 note, USC 42/1382h note", ex: "42 U.S.C. 421(m), 902(a)(5), 1382, 1382c, 1382h, 1383, and 1383b; secs. 4(c) and 5, 6(c)-(e), 14(a), and 15, Pub. L. 98-460, 98 Stat. 1794, 1801, 1802, and 1808 (42 U.S.C. 421 note, 423 note, and 1382h note)."},
  {expect: "USC 42/902(a)(5), USC 42/1382e, USC 42/1382g, USC 42/1383, STAT 87/155, USC 42/1382 note, STAT 87/956, USC 7/612c note, USC 7/1431 note, USC 42/1382e note, STAT 88/291", ex: "Secs. 702(a)(5), 1616, 1618, and 1631 of the Social Security Act (42 U.S.C. 902(a)(5), 1382e, 1382g, and 1383); sec. 212, Pub. L. 93-66, 87 Stat. 155 (42 U.S.C. 1382 note); sec. 8(a), (b)(1)-(b)(3), Pub. L. 93-233, 87 Stat. 956 (7 U.S.C. 612c note, 1431 note and 42 U.S.C. 1382e note); secs. 1(a)-(c) and 2(a), 2(b)(1), 2(b)(2), Pub. L. 93-335, 88 Stat. 291 (42 U.S.C. 1382 note, 1382e note)."},
  {expect: "USC 42/902(a)(5), USC 42/1395w-101, USC 42/1395w-114, USC 42/1395w-115", ex: "42 U.S.C. 902(a)(5),1395w-101, 1395w-114, and -115)"},
  {expect: "USC 44/2102 notes, USC 44/2104(a), USC 44/2112, USC 44/2903", ex: "44 U.S.C. 2102 notes, 2104(a), 2112, 2903."},
  {expect: "USC 46/701", ex: "46 U.S.C. Chapter 701"},
  {expect: "USC 46/3205, USC 46/3306, USC 46/3307, USC 46/70034, USC 46/701, PUBL 111/281, STAT 124/2905, EO 11735, FR 38/21243", ex: "46 U.S.C. 3205, 3306, 3307, 70034; 46 U.S.C. Chapter 701; sec. 617, Pub. L. 111-281, 124 Stat. 2905; E.O. 11735, 38 FR 21243, 3 CFR 1971-1975 Comp., p. 793; DHS Delegation 00170.1, Revision No. 01.4."},
  {expect: "USC 46/Appendix 1 preceding note", ex: "(see 46 U.S.C. App. note prec. 1)"},
  {expect: "USC 46/Appendix 1101, USC 46/Appendix 1114(b), USC 46/Appendix 1122(d), USC 46/Appendix 1241", ex: "46 App. U.S.C. 1101, 1114(b), 1122(d) and 1241; 49 CFR 1.66."},
  {expect: "USC 48/1806, PUBL 107/609, STAT 115/1012, PUBL 107/296, STAT 116/2135, USC 6/101 note", ex: "48 U.S.C. 1806; Pub. L. 107-609, 115 Stat. 1012; Pub. L. 107-296, 116 Stat. 2135 (6 U.S.C. 101 note)."},
  {expect: "USC 48/1806, USC 48/1806 note, USC 48/1807, USC 48/1808", ex: "48 U.S.C. 1806 and note, 1807, and 1808"},
  {expect: "USC 49/106(f), USC 49/42301 preceding note, PUBL 112/95, USC 49/44101, USC 49/44701-44702, USC 49/44705, USC 49/44709-44711, USC 49/44713", ex: "49 U.S.C. 106(f), 42301 preceding note added by Pub. L. 112-95, sec. 412, 126 Stat. 89, 44101, 44701-44702, 44705, 44709-44711, 44713;"},
  {expect: "USC 49/106(g), USC 49/5121-5124, USC 49/44802 note, USC 49/46101-46111, USC 49/46302, USC 49/46304-46316", ex: "49 U.S.C. 106(g), 5121-5124, 44802 (note), 46101-46111, 46302 (for a violation of 49 U.S.C. 46504), 46304-46316"},
  {expect: "USC 49/113, USC 49/501 et seq, USC 49/311, USC 49/313, USC 49/31502, PUBL 114/94, STAT 129/1312, STAT 129/1536, USC 42/4917", ex: "49 U.S.C. 113, 501 et seq., subchapters I and III of chapter 311, chapter 313, and 31502; sec. 5204 of Pub. L. 114-94, 129 Stat. 1312, 1536; 42 U.S.C. 4917; and 49 CFR 1.87"},
  {expect: "USC 49/329, USC 49/41102, USC 49/41301, USC 49/41708, USC 49/41709, USC 49/41712", ex: "49 U.S.C. 329 and chapters 41102, 41301, 41708, 41709, and 41712."},
  {expect: "USC 49/521, USC 49/31136, USC 49/31301 et seq, USC 49/31502", ex: "49 U.S.C. 521, 31136, 31301, et seq., and 31502; "},
  {expect: "USC 49/40101, USC 49/40101 note, USC 49/40105", ex: "49 U.S.C. 40101, 40101nt., 40105"},
  {expect: "USC 49/40102, USC 49/41706, PUBL 106/181, PUBL 112/95, USC 49/41711, USC 49/46301", ex: "49 U.S.C. 40102, 41706 as amended by section 708 of Pub. L. 106-181 and section 401 of Pub. L. 112-95, 41711, and 46301."},
  {expect: "USC 49/Appendix 1-85", ex: "49 App. U.S.C. 1-85 (1988)"},
  {expect: "USC 49/Appendix 211-213, USC 43/869 et seq, USC 48/360, USC 48/361", ex: "49 U.S.C. App., 211-213, 43 U.S.C. 869 et seq. 48 U.S.C 360, 361, unless otherwise noted."},
  {expect: "USC 50/1641 et seq, USC 50/1701 et seq, USC 50/Appendix 1-44, USC 50/Appendix 2411", ex: "50 U.S.C. 1641 et seq., 1701 et seq.; 50 U.S.C. App. 1-44, 2411."},
  {expect: "USC 50/Appendix 2061-2171, USC 50/Appendix 468", ex: "50 U.S.C. App. §§ 2061-2171; 50 U.S.C. App § 468;"},
  {expect: "USC 50/4801-4852, USC 50/4601 et seq, USC 50/1701 et seq, EO 13026, FR 61/58767, EO 13222, FR 66/44025, NOTICE 2023-08-14, FR 88/55549", ex: "50 U.S.C. 4801-4852; 50 U.S.C. 4601 et seq.; 50 U.S.C. 1701 et seq.; E.O. 13026, 61 FR 58767, 3 CFR, 1996 Comp., p. 228; E.O. 13222, 66 FR 44025, 3 CFR, 2001 Comp., p. 783; Notice of August 14, 2023, 88 FR 55549 (August 16, 2023)."},
  {expect: "USC 50/Appendix 401, USC 50/Appendix 402", ex: "50 U.S.C. apps. 401, 402."},
  {expect: "USC 51/20113, PROCLAMATION 1995-03-23, FR 60/15845", ex: "51 U.S.C. 20113; Proclamation No. 6780 of March 23, 1995, 60 FR 15845"},

  {
    expect: "USC 5/Appendix App, USC 5/Appendix 3, USC 5/552",
    ex: "5 U.S.C. App; 5 U.S.C. App. 3; 5 U.S.C. 552",
    exempt_reference_keys: [:result, :link],
    expected_references: [
      {source: :usc, title: "5", section: "App", authority: {grouping: "Appendix", section: "App"}, hierarchy: {title: "5", section: "App"}, href_hierarchy: {title: "5", part: "App"}, text: "5 U.S.C. App"},
      {source: :usc, title: "5", appendix: "3", authority: {title: "5", grouping: "Appendix", section: "3"}, hierarchy: {title: "5", appendix: "3"}, href_hierarchy: {title: "5", appendix: "Appendix%203"}, text: "5 U.S.C. App. 3"},
      {source: :usc, title: "5", section: "552", hierarchy: {title: "5", section: "552"}, href_hierarchy: {title: "5", part: "552"}, text: "5 U.S.C. 552"}
    ]
  },

  {
    expect: "USC 50/Appendix 2061 et seq",
    ex: "50 U.S.C. App. 2061 et seq.",
    exempt_reference_keys: [:result, :link],
    expected_references: [
      {source: :usc, title: "50", appendix: "2061 et seq", authority: {title: "50", grouping: "Appendix", section: "2061 et seq"}, hierarchy: {title: "50", appendix: "2061 et seq"}, href_hierarchy: {title: "50", appendix: "Appendix%202061"}, suffix: ".", trailing_modifier: ", et seq", text: "50 U.S.C. App. 2061 et seq"}
    ]
  },

  {
    expect: "USC 5/Appendix",
    ex: "5 U.S.C. Appendix (Ethics in Government Act of 1978)",
    exempt_reference_keys: [:result],
    expected_references: [
      {source: :usc, title: "5", section: "Appendix", authority: {grouping: "Appendix", section: "Appendix"}, hierarchy: {title: "5", section: "Appendix"}, href_hierarchy: {title: "5", part: "Appendix"}, link: :not_present, text: "5 U.S.C. Appendix"}
    ]
  },

  {
    expect: "USC 5/Appendix App, USC 31/9701",
    ex: "5 U.S.C. App. (Sec. 1103, Civil Service Reform Act of 1978; 31 U.S.C. 9701).",
    exempt_reference_keys: [:result, :link],
    expected_references: [
      {source: :usc, title: "5", section: "App", authority: {grouping: "Appendix", section: "App"}, hierarchy: {title: "5", section: "App"}, href_hierarchy: {title: "5", part: "App"}, link: :not_present, text: "5 U.S.C. App."},
      {source: :usc, title: "31", section: "9701", hierarchy: {title: "31", section: "9701"}, href_hierarchy: {title: "31", part: "9701"}, text: "31 U.S.C. 9701"}
    ]
  },

  {
    expect: "USC 5/Appendix 1",
    ex: "5 U.S.C. app. 1",
    exempt_reference_keys: [:result, :href_hierarchy],
    expected_references: [
      {source: :usc, title: "5", appendix: "1", authority: {title: "5", grouping: "Appendix", section: "1"}, hierarchy: {title: "5", appendix: "1"}, link: :not_present, text: "5 U.S.C. app. 1"}
    ]
  },

  {
    expect: "USC 5/Appendix I",
    ex: "5 U.S.C. App. I Section 8(a).",
    exempt_reference_keys: [:result, :href_hierarchy],
    expected_references: [
      {source: :usc, title: "5", appendix: "I", authority: {title: "5", grouping: "Appendix", section: "I"}, hierarchy: {title: "5", appendix: "I"}, link: :not_present, text: "5 U.S.C. App. I"}
    ]
  },

  {
    expect: "USC 3/202, USC 3/208, PUBL 94/196, STAT 89/1109, USC 5/301",
    ex: "Secs. 202 and 208, Title 3, U.S. Code, as amended and added, respectively by Pub. L. 94-196 (89 Stat. 1109); 5 U.S.C. 301.",
    exempt_reference_keys: [:result, :link, :hierarchy, :href_hierarchy],
    expected_references: [
      {source: :usc, title: "3", section: "202", text: "202"},
      {source: :usc, title: "3", section: "208", text: "208"},
      {source: :publ, congress: 94, law: "196", text: "Pub. L. 94-196"},
      {source: :stat, volume: "89", chapter: "1109", text: "89 Stat. 1109"},
      {source: :usc, title: "5", section: "301", text: "5 U.S.C. 301"}
    ]
  },

  {
    expect: "USC 42/2011 et seq, USC 42/7101 et seq, USC 42/7144b et seq, USC 42/7383h-1, USC 50/2401 et seq",
    ex: "42 U.S.C. 2011, et seq., 7101, et seq., 7144b, et seq., 7383h-1; 50 U.S.C. 2401, et seq.",
    exempt_reference_keys: [:result, :link],
    expected_references: [
      {source: :usc, title: "42", section: "2011", authority: {section: "2011 et seq"}, hierarchy: {title: "42", section: "2011"}, href_hierarchy: {title: "42", part: "2011"}, text: "42 U.S.C. 2011, et seq."},
      {source: :usc, title: "42", section: "7101", authority: {section: "7101 et seq"}, hierarchy: {title: "42", section: "7101"}, href_hierarchy: {title: "42", part: "7101"}, text: "7101, et seq."},
      {source: :usc, title: "42", section: "7144b", authority: {section: "7144b et seq"}, hierarchy: {title: "42", section: "7144b"}, href_hierarchy: {title: "42", part: "7144b"}, text: "7144b, et seq."},
      {source: :usc, title: "42", section: "7383h-1", hierarchy: {title: "42", section: "7383h-1"}, href_hierarchy: {title: "42", part: "7383h-1"}, text: "7383h-1"},
      {source: :usc, title: "50", section: "2401", authority: {section: "2401 et seq"}, trailing_modifier: ", et seq", suffix: ".", hierarchy: {title: "50", section: "2401"}, href_hierarchy: {title: "50", part: "2401"}, text: "50 U.S.C. 2401, et seq"}
    ]
  },

  {
    expect: "USC 46/701",
    ex: "46 U.S.C. Chapter 701",
    exempt_reference_keys: [:result, :link],
    expected_references: [
      {source: :usc, title: "46", chapter: "701", section: "70101", authority: {section: "701"}, hierarchy: {title: "46", chapter: "701"}, href_hierarchy: {title: "46", chapter: "701"}, text: "46 U.S.C. Chapter 701"}
    ]
  },

  {
    expect: "USC 5/7301, USC 5/Appendix App, USC 47/154(b), USC 47/154(j), USC 47/154(i), USC 47/303(r), EO 12674, FR 54/15159, EO 12731, FR 55/42547",
    ex: "5 U.S.C. 7301; 5 U.S.C. App. (Ethics in Government Act of 1978); 47 U.S.C. 154(b), (j), (i) and 303(r); E.O. 12674, 54 FR 15159, 3 CFR, 1989 Comp., p. 215, as modified by E.O. 12731, 55 FR 42547, 3 CFR, 1990 Comp., p. 306; 5 CFR 2634.103, 2634.601(b), 2634.901(b).",
    exempt_reference_keys: [:result, :link],
    expected_references: [
      {source: :usc, title: "5", section: "7301", hierarchy: {title: "5", section: "7301"}, href_hierarchy: {title: "5", part: "7301"}, text: "5 U.S.C. 7301"},
      {source: :usc, title: "5", section: "App", authority: {grouping: "Appendix", section: "App"}, hierarchy: {title: "5", section: "App"}, href_hierarchy: {title: "5", part: "App"}, text: "5 U.S.C. App."},
      {source: :usc, title: "47", section: "154", sublocators: "(b)", hierarchy: {title: "47", section: "154", paragraph: "(b)"}, href_hierarchy: {title: "47", part: "154", sublocators: "(b)"}, text: "47 U.S.C. 154", suffix: "(b), ", authority: {section: "154(b)"}},
      {source: :usc, title: "47", section: "154", sublocators: "(j)", hierarchy: {title: "47", section: "154", paragraph: "(j)"}, href_hierarchy: {title: "47", part: "154", sublocators: "(j)"}, text: "(j)", authority: {section: "154(j)"}},
      {source: :usc, title: "47", section: "154", sublocators: "(i)", hierarchy: {title: "47", section: "154", paragraph: "(i)"}, href_hierarchy: {title: "47", part: "154", sublocators: "(i)"}, text: "(i)", authority: {section: "154(i)"}},
      {source: :usc, title: "47", section: "303", sublocators: "(r)", hierarchy: {title: "47", section: "303", paragraph: "(r)"}, href_hierarchy: {title: "47", part: "303", sublocators: "(r)"}, text: "303", suffix: "(r)", authority: {section: "303(r)"}},
      {source: :eo, eo_number: 12674, hierarchy: {eo_number: 12674}, text: "E.O. 12674"},
      {source: :federal_register, volume: "54", page: "15159", title: "54", section: "15159", hierarchy: {title: "54", section: "15159"}, href_hierarchy: {title: "54", part: "15159"}, text: "54 FR 15159"},
      {source: :eo, eo_number: 12731, hierarchy: {eo_number: 12731}, text: "E.O. 12731"},
      {source: :federal_register, volume: "55", page: "42547", title: "55", section: "42547", hierarchy: {title: "55", section: "42547"}, href_hierarchy: {title: "55", part: "42547"}, text: "55 FR 42547"}
    ]
  },

  {
    expect: "USC 5/1103(c), USC 5/2301, USC 5/2302, USC 5/4101 et seq",
    ex: "5 U.S.C. 1103(c), 2301, 2302, 4101, et seq.",
    exempt_reference_keys: [:result, :link],
    expected_references: [
      {source: :usc, title: "5", section: "1103", sublocators: "(c)", hierarchy: {title: "5", section: "1103", paragraph: "(c)"}, href_hierarchy: {title: "5", part: "1103", sublocators: "(c)"}, text: "5 U.S.C. 1103(c)", authority: {section: "1103(c)"}},
      {source: :usc, title: "5", section: "2301", hierarchy: {title: "5", section: "2301"}, href_hierarchy: {title: "5", part: "2301"}, text: "2301"},
      {source: :usc, title: "5", section: "2302", hierarchy: {title: "5", section: "2302"}, href_hierarchy: {title: "5", part: "2302"}, text: "2302"},
      {source: :usc, title: "5", section: "4101", authority: {section: "4101 et seq"}, hierarchy: {title: "5", section: "4101"}, href_hierarchy: {title: "5", part: "4101"}, text: "4101, et seq", suffix: ".", trailing_modifier: ", et seq"}
    ]
  }
]

RSpec.describe "ReferenceParser.new(only: :authorities)" do # rubocop:disable RSpec/DescribeClass
  describe "overlapping authority patterns" do
    let(:reference_parser) { ReferenceParser.new(only: :authorities, options: {include_unlinked: true}) }

    AUTHORITY_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s[..64].tr("\n", " ") do
          references = []
          reference_texts = []
          reference_parser.each(example) do |reference, source|
            authority = (reference[:authority] || {}).reverse_merge(reference[:hierarchy] || reference)

            a = authority.values_at(*%i[title congress volume plan_number eo_number determination_number directive_number]).compact.join(" ")
            b = [authority[:grouping], authority[:section]].compact.join(" ")
              .presence || authority.values_at(*%i[part appendix law chapter year]).compact.join(" ")
            b = "Appendix" if b == "Appendix Appendix" # grouping/section as expected, shortening to avoid confusion looking at specs
            c = reference.values_at(*%i[date]).compact.join(" ")
            references << reference
            reference_texts << "#{source.to_s.upcase.gsub("FEDERAL_REGISTER", "FR").gsub("REORGANIZATION_PLAN", "RP")} #{[a, b, c].select(&:present?).join("/")}"
          end
          expect(reference_texts).to eq(scenario[:expect].split(",").map(&:strip))
          scenario[:expected_authority]&.each do |expected_rank, expected_value|
            expect(references.map { it[:authority] }).to include({expected_rank => expected_value})
          end

          expect_matching_references(references, scenario)
        end
      end
    end
  end
end
