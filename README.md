# ICLAB-2025-SPRING
## 心得
1. 沒事不要修
2. 沒事不要修
3. 但助教群真的很棒很好，感謝他們
4. 沒事不要修

## 有關我的 code
為了不要誤人子弟，我只放了我覺得排名比較好的。

## Ranking for Reference
| Lab  | Ranking |人數(1, 2, 3 de)| 1 de rate
| -------------------------------------------            | -- |--- | -- |
| Lab02 - MAZE (Sequential Circuit)                      | *2 | 130 | 55% |
| Lab03 - Static Timing Analysis (Testbench and Pattern) | 3 | 123 | 60% |
| Lab04 - Two Head Attention (DW IP)                     | 2 | 128 | 73% |
| Lab06 - BCH Codes Decoder (Soft IP)                    | 5 | 118 | 64% |
| MP    - Maze Routing Accelerator (DRAM, AXI)           | 1 | 113 | 72% |
| Lab08 - Siamese Neural Network (Low Power)             | 5 | 121 | 72% |
| Lab09 - Autonomous Flower Shop System (DRAM, AXI, SV)  | 2 | 120 | 69% |
| Lab10 - Verification of Lab09 (Coverage)               | 1 | 117 | 68% |
| FP    - Single Core Central Processing Unit (CA, DRAM, AXI) | 4 | 113 | 75% |

*代表這個 lab 我 2de（Lab2 就 2de 真的讓我超崩潰，後來憤而用了超激進優化方式，好孩子不要學，細節參照 Lab2 的 README）

(全部總共 13 次有 ranking 的作業，只放了排名比較好的其中 9 次 code，剩下大都落在十幾名左右，Lab1 最爛，來到 21，就通通都不放 code 了，不過很想要的話可以發一個 issue)


## Performace / Life balance 策略
### （一）

在 OT 前盡可能努力衝高名次，後面就可以好好的兩腿一伸躺平了。

### （二）

在追求排行榜上的最高 performace 時，努力和收穫是不成正比的，想要聰明的拼 perfomance 同時保有生活品質，就需要仔細觀察自己的狀態，
以個人為例，寫出第一版差不多都會落在某一個固定的名次區間，但每往上一名，付出的心力會是越來越大的，Lab9 我幾乎花了一個禮拜反覆優化，但大概進步 2、3 名而已。
所以可以仔細觀察自己的排名狀態，聰明的抓到甜蜜點，不要太累了，嗚嗚。

### （三）
花在 verification 上的時間建議是一天或更多，我在 Lab2 有 2de 過，這是我個人的血淚談。

### （四）
不要害怕花很多時間想架構，我通常會花兩天在想，並且期間絕不碰 design，因為大部分的 Lab 行數都落在 1000 上下，只要架構有想清楚就可以打得很快，所以不用擔心太晚開始，但禮拜五晚上至少要出一版架構然後開始寫。

## Coding Style
Coding style 是一個很玄的東西，我自己寫下來的心得是一個電路的 PPA 好不好，取決於三個部分：coding style 25%、算法和架構 60%、優化（用 shift register 之類的小技巧）15%，其中最玄的要數 coding style，佔比有時候能來到 40%。有時候把某些東西放在一個 always block 面積會小，另一些時候則反之，有時候把 FF 的 else 補完面積會比較小，另一些時候則反之。

說實話這挺令人沮喪，這點在複雜的電路會有更多體現，比如 MP，大家都用差不多的演算法，但就是有人面積會大到不科學，隨著慢慢改 coding style 才降下來，我個人覺得這其實是 iclab 這門課裡最吃天賦的一環，coding style 就是一種難以言喻的感覺。但好在只要你夠拼，試過各種 coding style 組合就可以部分彌補這個問題。

## 穩健的心態
Lab3 是一個 checkpoint，在這時候你多少可以看出自己對這個到底有沒有感覺，如果你寫到這邊發現你根本是個 coding style + 算法 + 優化三位一體的金童，恭喜你，保重好身體，你可以開始爬榜的魔瘋之路了。

但如果你發現你對這個沒有足夠多感覺也沒關係的，接下來的 Lab4、Lab5、MP 都會非常的難，只要穩穩地以 1de 為最高指導原則（但還是要注意不要賠光 performance），最後一定還是可以拿到亮眼的成績，這學期有看到一些人打超保守牌，事事以不 2de 為目標，最後成績還是非常的亮眼，不失為一條可行的路。


## 我犯的錯
沒有好好休息，排行榜前五名都整個卷爆，早該放開心胸多休息了，我有點懷疑花這麼多時間拼來的名次到底有沒有用 = =，有待我找完工作跟各位分享。

整個學期的作息就是

禮拜三：看 SPEC + 寫 pattern （有時候是隊友寫）+ 想架構

禮拜四：想架構一整天

禮拜五：想架構 + 寫

禮拜六：開始驗證

禮拜天：進行最後的優化

禮拜一：去土地公廟拜拜

剩下時間處理各種雜事

## Contact
```en.cs10@nycu.edu.tw```


## 鳴謝
Special shout out to XDEv11、kevin861222、hankshyu，感謝他們慷慨的分享，教了我怎麼寫 verilog 和修課的心態

也感謝我的隊友 charlestsai、hsin，真的非常的給力
