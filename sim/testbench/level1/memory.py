#!/usr/bin/python
from test import TestSuite
suite = TestSuite("data/memory.tc")
suite.addSignal("s_enable_ocram", 1, alias="ocram", default=False)
suite.addSignal("s_reset", 1, alias="reset", default=True)
suite.addSignal("s_mem_in.rddata", 32, alias="rddata", default=0)
suite.addSignal("s_mem_in.busy", 1, alias="busy", default=0)
suite.addSignal("a_mem_out.address", 21, alias="addr", default="---------------------")
suite.addSignal("a_mem_out.rd", 1, alias="rd", default=False)
suite.addSignal("a_mem_out.wr", 1, alias="wr", default=False)
suite.addSignal("a_mem_out.byteena", 4, alias="byteena", default="----")
suite.addSignal("a_mem_out.wrdata", 32, alias="wrdata", default="--------------------------------")
suite.printSignalAssignments()
suite.test(0, )
suite.test(1, ocram=False, rd=False, wr=False)
suite.test(2, ocram=False, rd=False, wr=False)
suite.test(3, ocram=False, rd=False, wr=False)
suite.test(4, ocram=False, rd=False, wr=False)
suite.test(5, ocram=False, rd=False, wr=False)
suite.test(6, ocram=False, rd=False, wr=False)
suite.test(7, ocram=False, rd=False, wr=False)
suite.test(8, ocram=False, rd=False, wrdata="00010010001101000000000000000000", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(9, ocram=False, rd=False, wr=False)
suite.test(10, ocram=False, rd=False, wr=False)
suite.test(11, ocram=False, rd=False, wr=False)
suite.test(12, ocram=False, rd=False, wr=False)
suite.test(13, ocram=False, rd=False, wr=False)
suite.test(14, ocram=False, rd=False, wrdata="00010010001101000101011001111000", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(15, ocram=False, rd=False, wr=False)
suite.test(16, ocram=False, rd=False, wr=False)
suite.test(17, ocram=False, rd=False, wr=False)
suite.test(18, ocram=False, rd=False, wr=False)
suite.test(19, ocram=False, rd=False, wr=False)
suite.test(20, ocram=False, rd=False, wrdata="11111110110111000000000000000000", addr="000000000000000001000", wr=True, byteena="1111")
suite.test(21, ocram=False, rd=False, wr=False)
suite.test(22, ocram=False, rd=False, wr=False)
suite.test(23, ocram=False, rd=False, wr=False)
suite.test(24, ocram=False, rd=False, wr=False)
suite.test(25, ocram=False, rd=False, wr=False)
suite.test(26, ocram=False, rd=False, wrdata="11111110110111001011101010011000", addr="000000000000000001000", wr=True, byteena="1111")
suite.test(27, ocram=False, rd=False, wr=False)
suite.test(28, ocram=False, rd=False, wr=False)
suite.test(29, ocram=False, rd=False, wrdata="00010010001101000101011001111000", addr="111001011101010011000", wr=True, byteena="1111")
suite.test(30, ocram=False, rd=False, wrdata="00010010001101000101011001111000", addr="111001011101010011100", wr=True, byteena="1111")
suite.test(31, ocram=False, rd=False, wrdata="11111110110111001011101010011000", addr="101000101011010000000", wr=True, byteena="1111")
suite.test(32, ocram=False, rd=False, wrdata="11111110110111001011101010011000", addr="101000101011010000100", wr=True, byteena="1111")
suite.test(33, ocram=False, rd=False, wrdata="0101011001111000----------------", addr="111001011101010011000", wr=True, byteena="1100")
suite.test(34, ocram=False, rd=False, wrdata="----------------0101011001111000", addr="111001011101010011010", wr=True, byteena="0011")
suite.test(35, ocram=False, rd=False, wrdata="1011101010011000----------------", addr="101000101011010000000", wr=True, byteena="1100")
suite.test(36, ocram=False, rd=False, wrdata="----------------1011101010011000", addr="101000101011010000010", wr=True, byteena="0011")
suite.test(37, ocram=False, rd=False, wrdata="01111000------------------------", addr="111001011101010011000", wr=True, byteena="1000")
suite.test(38, ocram=False, rd=False, wrdata="--------01111000----------------", addr="111001011101010011001", wr=True, byteena="0100")
suite.test(39, ocram=False, rd=False, wrdata="----------------01111000--------", addr="111001011101010011010", wr=True, byteena="0010")
suite.test(40, ocram=False, rd=False, wrdata="------------------------01111000", addr="111001011101010011011", wr=True, byteena="0001")
suite.test(41, ocram=False, rd=False, wrdata="10011000------------------------", addr="101000101011010000000", wr=True, byteena="1000")
suite.test(42, ocram=False, rd=False, wrdata="--------10011000----------------", addr="101000101011010000001", wr=True, byteena="0100")
suite.test(43, ocram=False, rd=False, wrdata="----------------10011000--------", addr="101000101011010000010", wr=True, byteena="0010")
suite.test(44, ocram=False, rd=False, wrdata="------------------------10011000", addr="101000101011010000011", wr=True, byteena="0001")
suite.test(45, ocram=False, rd=True, wr=False, rddata="0x456789AB", addr="000000000000000000100")
suite.test(46, ocram=False, rd=True, wr=False, rddata="0x456789AB", addr="000000000000000000100")
suite.test(47, ocram=False, rd=True, wr=False, rddata="0x456789AB", addr="000000000000000000110")
suite.test(48, ocram=False, rd=True, wr=False, rddata="0x456789AB", addr="000000000000000001000")
suite.test(49, ocram=False, rd=True, wr=False, rddata="0x456789AB", addr="000000000000000001010")
suite.test(50, ocram=False, rd=True, wr=False, rddata="0x456789AB", addr="000000000000000000100")
suite.test(51, ocram=False, rd=True, wr=False, rddata="0x456789AB", addr="000000000000000000101")
suite.test(52, ocram=False, rd=True, wr=False, rddata="0x456789AB", addr="000000000000000000110")
suite.test(53, ocram=False, rd=True, wr=False, rddata="0x456789AB", addr="000000000000000000111")
suite.test(54, ocram=False, rd=True, wr=False, rddata="0x456789AB", addr="000000000000000001000")
suite.test(55, ocram=False, rd=True, wr=False, rddata="0x456789AB", addr="000000000000000001001")
suite.test(56, ocram=False, rd=True, wr=False, rddata="0x456789AB", addr="000000000000000001010")
suite.test(57, ocram=False, rd=True, wr=False, rddata="0x456789AB", addr="000000000000000001011")
suite.test(58, ocram=False, rd=False, wrdata="01000101011001111000100110101011", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(59, ocram=False, rd=False, wrdata="00000000000000000100010101100111", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(60, ocram=False, rd=False, wrdata="11111111111111111000100110101011", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(61, ocram=False, rd=False, wrdata="00000000000000000100010101100111", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(62, ocram=False, rd=False, wrdata="00000000000000001000100110101011", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(63, ocram=False, rd=False, wrdata="00000000000000000000000001000101", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(64, ocram=False, rd=False, wrdata="00000000000000000000000001100111", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(65, ocram=False, rd=False, wrdata="11111111111111111111111110001001", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(66, ocram=False, rd=False, wrdata="11111111111111111111111110101011", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(67, ocram=False, rd=False, wrdata="00000000000000000000000001000101", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(68, ocram=False, rd=False, wrdata="00000000000000000000000001100111", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(69, rd=False, wrdata="00000000000000000000000010001001", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(70, rd=False, wrdata="00000000000000000000000010101011", addr="000000000000000000100", wr=True, byteena="1111")
suite.test(71, rd=True, wr=False, ocram=False, busy=True, addr="000000000000000000100")
suite.test(72, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(73, rd=True, wr=False, ocram=False, busy=True, addr="000000000000000000100")
suite.test(74, rd=False, wr=False, ocram=False, busy=True)
suite.test(75, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(76, rd=True, wr=False, ocram=False, busy=True, addr="000000000000000000110")
suite.test(77, rd=False, wr=False, ocram=False, busy=True)
suite.test(78, rd=False, wr=False, ocram=False, busy=True)
suite.test(79, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(80, rd=True, wr=False, ocarm=False, busy=True, addr="000000000000000001000")
suite.test(81, rd=False, wr=False, ocram=False, busy=True)
suite.test(82, rd=False, wr=False, ocram=False, busy=True)
suite.test(83, rd=False, wr=False, ocram=False, busy=True)
suite.test(84, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(85, rd=True, wr=False, ocram=False, busy=True, addr="000000000000000001010")
suite.test(86, rd=False, wr=False, ocram=False, busy=True)
suite.test(87, rd=False, wr=False, ocram=False, busy=True)
suite.test(88, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(89, rd=True, wr=False, ocram=False, busy=True, addr="000000000000000000100")
suite.test(90, rd=False, wr=False, ocram=False, busy=True)
suite.test(91, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(92, rd=True, wr=False, ocram=False, busy=True, addr="000000000000000000101")
suite.test(93, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(94, rd=True, wr=False, ocram=False, busy=True, addr="000000000000000000110")
suite.test(95, rd=False, wr=False, ocram=False, busy=True)
suite.test(96, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(97, rd=True, wr=False, ocram=False, busy=True, addr="000000000000000000111")
suite.test(98, rd=False, wr=False, ocram=False, busy=True)
suite.test(99, rd=False, wr=False, ocram=False, busy=True)
suite.test(100, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(101, rd=True, wr=False, ocram=False, busy=True, addr="000000000000000001000")
suite.test(102, rd=False, wr=False, ocram=False, busy=True)
suite.test(103, rd=False, wr=False, ocram=False, busy=True)
suite.test(104, rd=False, wr=False, ocram=False, busy=True)
suite.test(105, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(106, rd=True, wr=False, ocram=False, busy=True, addr="000000000000000001001")
suite.test(107, rd=False, wr=False, ocram=False, busy=True)
suite.test(108, rd=False, wr=False, ocram=False, busy=True)
suite.test(109, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(110, rd=True, wr=False, ocram=False, busy=True, addr="000000000000000001010")
suite.test(111, rd=False, wr=False, ocram=False, busy=True)
suite.test(112, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(113, rd=True, wr=False, ocram=False, busy=True, addr="000000000000000001011")
suite.test(114, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(115, rd=False, wrdata="01000101011001111000100110101011", addr="000000000000000000100", wr=True, byteena="1111", ocram=False, busy=True)
suite.test(116, rd=False, wr=False, ocram=False, busy=True)
suite.test(117, rd=False, wr=False, ocram=False, rddata="0x456789AB")
suite.test(118, rd=False, wrdata="11111111111111111011101010011000", addr="000000000000000000100", wr=True, byteena="1111", ocram=False, busy=True)
suite.test(119, rd=False, wr=False, ocram=False, busy=True)
suite.test(120, rd=False, wr=False, ocram=False, busy=True)
suite.test(121, rd=False, wr=False, rddata="0x456789AB")
suite.test(122, rd=False, wrdata="11111111111111111000100110101011", addr="000000000000000000100", wr=True, byteena="1111", busy=True)
suite.test(123, rd=False, wr=False, busy=True)
suite.test(124, rd=False, wr=False, busy=True)
suite.test(125, rd=False, wr=False, busy=True)
suite.test(126, rd=False, wr=False)
suite.test(127, rd=False, wrdata="00000000000000001011101010011000", addr="000000000000000000100", wr=True, byteena="1111", busy=True)
suite.test(128, rd=False, wr=False, busy=True)
suite.test(129, rd=False, wr=False, busy=True)
suite.test(130, rd=False, wr=False)
suite.test(131, rd=False, wrdata="00000000000000001000100110101011", addr="000000000000000000100", wr=True, byteena="1111", busy=True)
suite.test(132, rd=False, wr=False, busy=True)
suite.test(133, rd=False, wr=False)
suite.test(134, rd=False, wrdata="11111111111111111111111110111010", addr="000000000000000000100", wr=True, byteena="1111", busy=True)
suite.test(135, rd=False, wr=False)
suite.test(136, rd=False, wrdata="00000000000000000000000001100111", addr="000000000000000000100", wr=True, byteena="1111", busy=True)
suite.test(137, rd=False, wr=False, busy=True)
suite.test(138, rd=False, wr=False)
suite.test(139, rd=False, wrdata="00000000000000000000000001110110", addr="000000000000000000100", wr=True, byteena="1111", busy=True)
suite.test(140, rd=False, wr=False, busy=True)
suite.test(141, rd=False, wr=False, busy=True)
suite.test(142, rd=False, wr=False)
suite.test(143, rd=False, wrdata="11111111111111111111111110101011", addr="000000000000000000100", wr=True, byteena="1111", busy=True)
suite.test(144, rd=False, wr=False, busy=True)
suite.test(145, rd=False, wr=False, busy=True)
suite.test(146, rd=False, wr=False, busy=True)
suite.test(147, rd=False, wr=False)
suite.test(148, rd=False, wrdata="00000000000000000000000010111010", addr="000000000000000000100", wr=True, byteena="1111", busy=True)
suite.test(149, rd=False, wr=False, busy=True)
suite.test(150, rd=False, wr=False, busy=True)
suite.test(151, rd=False, wr=False)
suite.test(152, rd=False, wrdata="00000000000000000000000001100111", addr="000000000000000000100", wr=True, byteena="1111", busy=True)
suite.test(153, rd=False, wr=False, busy=True)
suite.test(154, rd=False, wr=False)
suite.test(155, rd=False, wrdata="00000000000000000000000001110110", addr="000000000000000000100", wr=True, byteena="1111", busy=True)
suite.test(156, rd=False, wr=False)
suite.test(157, rd=False, wrdata="00000000000000000000000010101011", addr="000000000000000000100", wr=True, byteena="1111", busy=True)
suite.test(158, rd=False, wr=False, busy=True)
suite.test(159, rd=False, wr=False, busy=True)
suite.test(160, rd=False, wr=False)
suite.test(161, rd=False, wr=False)