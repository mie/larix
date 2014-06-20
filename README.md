larix
=====

Небольшой генератор статического блога, написанный на Ruby.

### Пример использования

После клона репозитория и установки гемов-зависимостей (`bundle install`) для начала создания блога следует отредактировать для своих нужд конфигурационный файл static.yml.

Далее можно приступать к добавлению новой статьи командой (третий опциональный аргумент позволяет явно задать URL новой публикации):

    larix post 'Hello world!' 'hello-world'
    
Последним аргументом здесь указывается заголовок будущей статьи.

Теперь можно перейти к редактированию нового файла, появившегося в каталоге `source`. Первой строкой в нем указан заголовой, далее - время создания, затем - пустая строка для добавления тэгов. Ниже вы можете поместить свой текст, отформатированный по желанию в формате Markdown.

Как только вы закончите редактирование статьи, выполните команду:
    
    larix build

которая создаст для вас все нужные статические страницы в каталоге `static`.

Кроме этого вы можете создать собственную тему оформления по примеру существующей `themes/default`.
