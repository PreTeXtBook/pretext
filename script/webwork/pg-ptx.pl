#!/usr/bin/env perl

use Mojo::Base -signatures, -async_await;
use Mojo::IOLoop;
use Getopt::Long qw(:config bundling);
use Mojo::DOM;
use Mojo::JSON;
use Encode;

use lib "$ENV{PG_ROOT}/lib";
use WeBWorK::PG::Localize;
use WeBWorK::PG;

my $pg_root = $ENV{PG_ROOT};

my ($templateDirectory, $tempDirectory, @extraMacroDirs);
GetOptions(
	'e|externalFileDir=s' => \$templateDirectory,
	't|tempDirectory=s'   => \$tempDirectory,
	'm|extraMacroDir=s'   => \@extraMacroDirs
);

$templateDirectory =~ s|/?$|/| if $templateDirectory;
$tempDirectory     =~ s|/?$|/| if $tempDirectory;

my %translationOptions = (
	showSolutions       => 1,
	showHints           => 1,
	processAnswers      => 1,
	displayMode         => 'PTX',
	language_subroutine => WeBWorK::PG::Localize::getLoc('en'),
	macrosPath          => [
		'.',                     @extraMacroDirs,
		"$pg_root/macros",       "$pg_root/macros/answers",
		"$pg_root/macros/capa",  "$pg_root/macros/contexts",
		"$pg_root/macros/core",  "$pg_root/macros/deprecated",
		"$pg_root/macros/graph", "$pg_root/macros/math",
		"$pg_root/macros/misc",  "$pg_root/macros/parsers",
		"$pg_root/macros/ui"
	],
	$templateDirectory ? (templateDirectory => $templateDirectory) : (),
	$tempDirectory     ? (tempDirectory     => $tempDirectory)     : ()
);

Mojo::IOLoop->server(
	{ path => "$tempDirectory/pg-ptx.sock" } => sub ($loop, $stream, $id) {
		$stream->on(
			read => async sub ($stream, $bytes) {
				if (!$bytes || $bytes eq 'quit') {
					$loop->stop;
					return;
				}

				my $params = Mojo::JSON::decode_json($bytes);

				return $stream->write('error: Invalid parameters')
					unless defined $params->{source} || defined $params->{sourceFilePath};

				my $result = await $loop->subprocess->run_p(sub {
					my $pg = WeBWorK::PG->new(
						%translationOptions,
						problemSeed => $params->{problemSeed} // 1234,
						$params->{problemUUID}    ? (problemUUID    => $params->{problemUUID})    : (),
						$params->{sourceFilePath} ? (sourceFilePath => $params->{sourceFilePath}) : (),
						$params->{source}         ? (r_source       => \($params->{source}))      : ()
					);

					warn "errors:\n$pg->{errors}"     if $pg->{errors};
					warn "warnings:\n$pg->{warnings}" if $pg->{warnings};

					my $dom = Mojo::DOM->new->xml(1);
					for my $answer (sort keys %{ $pg->{answers} }) {
						$dom->append_content($dom->new_tag(
							$answer,
							ans_name                 => $pg->{answers}{$answer}{ans_name} // '',
							correct_ans              => $pg->{answers}{$answer}{correct_ans} // '',
							correct_ans_latex_string => $pg->{answers}{$answer}{correct_ans_latex_string} // ''
						));
					}
					$dom->wrap_content('<answerhashes></answerhashes>');
					my $answerhashXML = $dom->to_string;

					my $xml = "<webwork>$answerhashXML\n$pg->{body_text}\n</webwork>";

					$pg->free;

					return $xml;
				});

				return $stream->write(Encode::encode('UTF-8', "${result}ENDOFSOCKETDATA"));
			}
		);
		$stream->on(close => sub ($) { $loop->stop });
		$stream->timeout(0);
	}
);

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
