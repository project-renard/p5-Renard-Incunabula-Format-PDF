#!/usr/bin/env perl

use Test::Most;

use lib 't/lib';
use CurieTestHelper;

use Renard::Curie::Setup;
use Renard::Curie::App;
use Function::Parameters;

my $pdf_ref_path = try {
	CurieTestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
} catch {
	plan skip_all => "$_";
};

plan tests => 1;

fun print_tree_store($store, $callback) {
    walk_tree_store($store, fun( $level, $data ) {
	say "\t"x$level . join ":", @$data;
    });
}

fun walk_tree_store($store, $callback) {
    my $rootiter = $store->get_iter_first();
    walk_rows($store, $rootiter, 0, $callback);
}

fun walk_rows($store, $treeiter, $level, $callback) {
	my $valid = 1;
	while($valid) {
		my @array = $store->get( $treeiter, 0 .. $store->get_n_columns - 1);
		$callback->( $level, \@array );
		if( $store->iter_has_child($treeiter) ) {
			my $childiter = $store->iter_children($treeiter);
			walk_rows($store, $childiter, $level + 1, $callback);
		}
		$valid = $store->iter_next($treeiter);
	}
}

subtest 'Check that moving forward and backward changes the page number' => fun {
	my $app = Renard::Curie::App->new;
	$app->open_pdf_document( $pdf_ref_path );
	my $doc = $app->page_document_component->document;
	my $outline = $doc->outline;

	#print_tree_store($app->outline->model);
	my $tree_store_data = [];
	walk_tree_store( $app->outline->model, fun($level, $data ) {
		push @$tree_store_data,
			{
				level => $level,
				text => $data->[0],
				page => $data->[1],
			};
	});
	is_deeply( $tree_store_data, $outline->items,
		'Outline tree store matches outline data');
};

done_testing;
