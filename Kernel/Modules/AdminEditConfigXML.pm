# --
# Copyright (C) 2020 - 2022 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminEditConfigXML;

use strict;
use warnings;

use File::Basename;
use File::Spec;

our @ObjectDependencies = qw(
    Kernel::Output::HTML::Layout
    Kernel::System::Web::Request
    Kernel::Config
    Kernel::System::Main
    Kernel::System::XML::Simple
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject     = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $MainObject      = $Kernel::OM->Get('Kernel::System::Main');
    my $XMLSimpleObject = $Kernel::OM->Get('Kernel::System::XML::Simple');

    my @Params = qw(File Content Reload);
    my %GetParam;
    for my $Param (@Params) {
        $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
    }

    if ( $GetParam{File} ) {
        $GetParam{File} = basename( $GetParam{File} );
    }

    my $Path = File::Spec->catdir( $ConfigObject->Get('Home'), qw/Kernel Config Files XML/ );

    if ( $Self->{Subaction} eq 'Save' ) {
        if ( !$GetParam{File} ) {
            return $LayoutObject->Attachment(
                ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
                Content     => '{"Success":0, "Message":"No File given"}',
                Type        => 'inline',
                NoCache     => 1,
            );
        }

        if ( !$GetParam{Content} ) {
            return $LayoutObject->Attachment(
                ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
                Content     => '{"Success":0, "Message":"No Content given"}',
                Type        => 'inline',
                NoCache     => 1,
            );
        }

        # check XML
        my $Success = $XMLSimpleObject->XMLIn( XMLInput => $GetParam{Content} );

        if ( !$Success ) {
            return $LayoutObject->Attachment(
                ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
                Content     => $LayoutObject->JSONEncode( Data => {"Success" => 0, "Message" => "Invalid XML" } ),
                Type        => 'inline',
                NoCache     => 1,
            );
        }

        # save to file
        my $Location = $MainObject->FileWrite(
            Directory => $Path,
            Filename  => $GetParam{File},
            Content   => \$GetParam{Content},
        );

        # reload config
        if ( $GetParam{Reload} ) {
            # Get SysConfig object.
            my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

            my $Success = $SysConfigObject->ConfigurationXML2DB(
                UserID  => 1,
                Force   => 1,
                CleanUp => 1,
            );

            if ( $Success ) {
                my %DeploymentResult = $SysConfigObject->ConfigurationDeploy(
                    Comments    => "Configuration Rebuild",
                    AllSettings => 1,
                    UserID      => 1,
                    Force       => 1,
                );
            }
        }

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => '{"Success":1}',
            Type        => 'inline',
            NoCache     => 1,
        );
    }
    elsif ( $Self->{Subaction} eq 'File' ) {
        if ( !$GetParam{File} ) {
            return $LayoutObject->Attachment(
                ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
                Content     => '{"Success":0, "Message":"No File given"}',
                Type        => 'inline',
                NoCache     => 1,
            );
        }

        my $ContentRef = $MainObject->FileRead(
            Directory       => $Path,
            Filename        => $GetParam{File},
            DisableWarnings => 1,
            Result          => 'SCALAR',
        );

        $ContentRef //= \"";

        if ( !${$ContentRef} ) {
            return $LayoutObject->Attachment(
                ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
                Content     => '{"Success":0, "Message":"Could not read file"}',
                Type        => 'inline',
                NoCache     => 1,
            );
        }

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $LayoutObject->JSONEncode( Data => {"Success" => 1, Content => ${$ContentRef}, File => $GetParam{File}} ),
            Type        => 'inline',
            NoCache     => 1,

        );
    }
    else {
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Self->_MaskForm();
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

sub _MaskForm {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    my $Path = File::Spec->catdir( $ConfigObject->Get('Home'), qw/Kernel Config Files XML/ );

    my @FileList = map{ $_ =~ s/\Q$Path\E//; $_ }$MainObject->DirectoryRead(
        Directory => $Path,
        Filter    => '*.xml',
    );

    $Param{ConfigFilesSelect} = $LayoutObject->BuildSelection(
        Data       => \@FileList,
        Name       => 'FileSelect',
        Size       => 1,
        HTMLQuote  => 1,
        Class      => 'Modernize',
    );

    return $LayoutObject->Output(
        TemplateFile => 'AdminEditConfigXML',
        Data         => \%Param
    );
}

1;
