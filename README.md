# IESfromCaustics
## 3dsmax script – Генератор IES на основании каустики светильника

Базовая идея описана мною на сайте [3ddd](https://3ddd.ru/blog/post/ies_dlia_nakladnykh_tochiechnykh_svietil_nikov_na_osnovie_sfierichieskoi_proiektsii_kaustiki).  
В последствии был написан данный [скрипт](https://3ddd.ru/blog/post/skript_dlia_sozdaniia_ies_dlia_vstroiennykh_svietil_nikov_na_osnovie_sfierichieskoi_proiektsii_kaustiki).

## Требования
Для работы скрита необходим установленный 3dsmax + VRay

## Установка
* Скачате файл *.mzp из [install](./install/)
* Перетащите его в окно 3dsmax
* Зайдите в меню: ```Customize -> Cuctomize User Interface... -> Toolbars -> Category -> #PankovScripts```
* Перетащите ```IES from Caustics generator``` на любую панель
* При нажатии на кнопу запускается основное окно приложения


# История версий

## 1.0 beta – 21.03.2016
Начальный функционал:
* Загрузка сцен для генерации каустики Vray и тестирования IES файла Vray
* Поля основных записей в IES файл: Manufacturer, Model, Lamp Type, Power consumption, Luminous power, Size
* Задание детализации IES фала
* Сохранение положения окна

<img src="./docs/v1.0b/v1.0b main window.png" alt="main window" width="300"/>