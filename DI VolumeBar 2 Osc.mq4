//+------------------------------------------------------------------+
//|                                             DI VolBars 2 Osc.mq4 |
//|                                   Copyright 2015, Iglakov Dmitry |
//|                                               cjdmitri@gmail.com |
//+------------------------------------------------------------------+
#property copyright  "Copyright 2015, Iglakov Dmitry"
#property link       "cjdmitri@gmail.com"
#property version    "2.0"
#property strict
#property indicator_separate_window
#property description "Volume indicator bars"
#property icon        "\\Images\\DI VolBars 2 Osc_LOGO.ico";  
#property indicator_buffers 4       // Количество буферов
#property indicator_color1 Blue     // Цвет нормальной гистограммы
#property indicator_color2 Red      // Цвет линии среднего значения
#property indicator_color3 Green    // Цвет гистограммы аномального объема
#property indicator_color4 Yellow   // Цвет линии среднего объема за выбраный период

/*
Описание
Индикатор показывает объем каждого бара в пунктах, в виде гистограммы.
Вторая версия индикатора. Теперь в виде осциллятора. Более информативный и функциональный. При этом не загружает основной график.

Показывает:
- объем бара в пунктах, в виде гистограммы (буфер 0)
- среднее значение объема, за весь период (буфер 1)
- другим цветом бары, которые выше клиентского среднего значения (буфер 2)
- среднее значение, за количество баров установленное пользователем (буфер 3)

А так же:
- настройка показа значений индикатора
- отображение объема в реальном времени (нулевой бар)
- настраиваемый сигнал,  при привышении среднего значения установленного пользователем


Параметры:
VolumeAlert - сигнал, при привышении среднего значения установленного пользователем
ShowAverVol - показ среднего значения за все бары
ShowAverVolClient - расчет среднего значение за количество баров, установленное пользователем
BarsCount - количество баров для расчета среднего значения
*/


extern  bool       VolumeAlert = true;              //Alert Volume
extern  bool       ShowAverVol = true;
extern  bool       ShowAverVolClient = true;
extern  int        BarsCount   = 400;


double   Buf_0[],                //Буфер 0 показывающий объем всех баров
         Buf_1[],                //Буфер 1 показывает линию среднего значения за все бары
         Buf_1_An[],             //Буфер 2 показывает бары, чье значение выше среднего 
         Buf_3[];                //Буфер 3 показывает среднее значение, по количеству баров пользователя
datetime timeBarAlert;        //На каком баре сработал сигнал



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   string short_name;
   IndicatorDigits(Digits);
   SetIndexBuffer(0,Buf_0);         // Назначение массива буферу
   SetIndexStyle (0,DRAW_HISTOGRAM, STYLE_SOLID,2);// Стиль линии
   SetIndexBuffer(1,Buf_1);         // Назначение массива буферу
   SetIndexStyle (1,DRAW_LINE, STYLE_DASH,1);// Стиль линии
   SetIndexBuffer(2,Buf_1_An);         // Назначение массива буферу
   SetIndexStyle (2,DRAW_HISTOGRAM, STYLE_SOLID,2);// Стиль линии
   SetIndexBuffer(3,Buf_3);         // Назначение массива буферу
   SetIndexStyle (3,DRAW_LINE, STYLE_SOLID,2);// Стиль линии
   //--- имя для отображения в DataWindow
   short_name = "DI Volume Bar";
   IndicatorShortName(short_name);
   SetIndexLabel(0,short_name);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   double      summVol = 0;                 //Переменная для определения объема всех баров
   double      summVolClient = 0;
   int         limit = rates_total - prev_calculated;
   if(prev_calculated>0)
      {limit++;}
//Определение объема для каждого бара   
   for(int i = 0; i < limit; i++) //Перечисляем все бары
   {
      double h = NormalizeDouble(high[i], Digits);    //Максимальная цена текущего бара
      double l = NormalizeDouble(low[i], Digits);     //Минимальная цена текущего бара
      double Vol = h - l;                             //Объем текущего бара
      Buf_0[i] = NormalizeDouble(Vol, Digits);        //Присваиваем буферу индикатора значение 
   }//Перечисляем все бары
     
//==============Показываем среднее значени  
   if (ShowAverVol == true) //Если необходимо показывать среднее значение а количество баров
   {
      for(int w = rates_total - 1; w >= 0; w--)
      {
         summVol = summVol + Buf_0[w];     //Определяем объем всех баров
         double averVol = NormalizeDouble(summVol/(rates_total - (w-1)), Digits); //Определили средний объем бара
         Buf_1[w] = NormalizeDouble(averVol, Digits); //Присваиваем буферу индикатора значение
      }
   }//Если необходимо показывать среднее значение а количество баров  
         
//=================Среднее значение по количеству баров клиента
   if (ShowAverVolClient == true) //Если необходимо показывать среднее значение а количество баров
   {
      //Если указано количество больше чем всего баров вистории
      if(BarsCount - 2 > rates_total)
      {BarsCount = rates_total-2;}
      for(int a = BarsCount; a >= 0; a--)
      {
         summVolClient = summVolClient + Buf_0[a];     //Определяем объем всех баров
         double averVolClient = NormalizeDouble(summVolClient/(BarsCount - (a-1)), Digits); //Определили средний объем бара
         Buf_3[a] = NormalizeDouble(averVolClient, Digits); //Присваиваем буферу индикатора значение
      }
   }//Если необходимо показывать среднее значение а количество баров
     
//==================Новы цикл определения аномального объема
   for(int t = rates_total - 1; t >= 0; t--) //Перечисляем все видимые бары
   {
      if (Buf_0[t] > Buf_3[t])
      {
         Buf_1_An[t] = Buf_0[t];
      }
   }//Новы цикл определения аномального объема

//==============Показываем Алерт при достижении заданного объема на нулевом баре
   if (VolumeAlert == true) //если необходимо показывать алерт
   {
      if (Buf_0[0] > Buf_3[0])   //Если объем нулевого бара выше установленного
      {
         if (timeBarAlert != iTime(Symbol(), Period(), 0))//если алерт еще не срабатывал
         {
            Alert("Bar 0 volume (", Buf_0[0],  ") > Average Volume Client (", Buf_3[0], ")");
            timeBarAlert = iTime(Symbol(), Period(), 0); //присваиваем значение для исключения повторного срабатывания
         }//если алерт еще не срабатывал
            
      } //Если объем нулевого бара выше установленного
   } //если необходимо показывать алерт

   return(rates_total);
  }
//+------------------------------------------------------------------+



