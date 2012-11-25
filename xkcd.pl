#!/usr/bin/perl -w

use WWW::Mechanize;
use Image::Magick;
use HTML::Entities;
use List::Util qw[min max];

# break the text in many lines if necessary
sub prepareText {
    my %args = @_;
    $image = $args{image};
    $text = $args{text};
    $pointsize = $args{pointsize};
    $lastSpace = 0;
    for($j = 0; $j != length($text); $j++) {
        if(substr($text,$j,1) eq " ") {
            ($_, $_, $_, $_, $width, $_, $_) = $image->QueryMultilineFontMetrics(text => substr($text, 0, $j), pointsize => $pointsize );
            if($width > 560){ # max text width to look good on screen
                substr($text, $lastSpace, 1)="\n";
            }
            $lastSpace = $j;
        }
    }
    return $text;
}

$m = WWW::Mechanize->new();
$titlePointSize = 20;
$altPointSize = 30;
for($i = 0; $i != 100 ; $i++) { # gets 100 random comics
    $m->get("http://dynamic.xkcd.com/random/comic/");

    if($m->content =~ m/(http:\/\/imgs.xkcd.com\/comics\/((\w)+\.(.*)))" title="(.*)" alt="(.*)" /) {
        $url = $1;
        $fileName = $2;
        $extension = $4;
        $filePath = "/tmp/$fileName";

        # decodes eventual html entities contained in the texts
        $title = decode_entities($5)." ";
        $alt = decode_entities($6)." ";

        $m->get($url);
        open IMAGE, '>', "$filePath" or die "Can't open file '$filePath'";
        print IMAGE $m->content;
        close IMAGE;

        my $image = Image::Magick->new;
        $image->read($filePath);

        $title = prepareText(image => $image, text => $title, pointsize => $titlePointSize);
        $alt = prepareText(image => $image, text => $alt, pointsize => $altPointSize);

        $heightAlt = ($image->QueryMultilineFontMetrics(text => $alt, pointsize => $altPointSize ))[5];
        $heightTitle = ($image->QueryMultilineFontMetrics(text => $title, pointsize => $titlePointSize ))[5];

        $height = 800-2*max($heightTitle,$heightAlt)-5; # leaves space for title, alt and some space
        $image->Set(Gravity => 'Center');
        $image->Resize(geometry => "600x$height");
        $image->Extent(geometry => '600x800'); # extends the image mantaining comic in the middle
        $image->Annotate(y => 5, gravity => 'North', pointsize => $altPointSize, text => $alt);
        $image->Annotate(gravity =>'South', pointsize => $titlePointSize, text => $title);
        $image->Quantize(colorspace => 'gray');
        $image->Write("xkcd_$i.$extension"); # writes image file
    }
    unlink($filePath); # removes temporary image file
}
exit 0;

