#include "clar_libgit2.h"
#include "posix.h"
#include "path.h"
#include "fileops.h"

static git_repository *g_repo = NULL;

void test_attr_ignore__initialize(void)
{
	g_repo = cl_git_sandbox_init("attr");
}

void test_attr_ignore__cleanup(void)
{
	cl_git_sandbox_cleanup();
	g_repo = NULL;
}

void assert_is_ignored_(
	bool expected, const char *filepath, const char *file, int line)
{
	int is_ignored = 0;

	cl_git_pass_(
		git_ignore_path_is_ignored(&is_ignored, g_repo, filepath), file, line);

	clar__assert_equal(
		file, line, "expected != is_ignored", 1, "%d",
		(int)(expected != 0), (int)(is_ignored != 0));
}
#define assert_is_ignored(expected, filepath) \
	assert_is_ignored_(expected, filepath, __FILE__, __LINE__)

void test_attr_ignore__honor_temporary_rules(void)
{
	cl_git_rewritefile("attr/.gitignore", "/NewFolder\n/NewFolder/NewFolder");

	assert_is_ignored(false, "File.txt");
	assert_is_ignored(true, "NewFolder");
	assert_is_ignored(true, "NewFolder/NewFolder");
	assert_is_ignored(true, "NewFolder/NewFolder/File.txt");
}

void test_attr_ignore__allow_root(void)
{
	cl_git_rewritefile("attr/.gitignore", "/");

	assert_is_ignored(false, "File.txt");
	assert_is_ignored(false, "NewFolder");
	assert_is_ignored(false, "NewFolder/NewFolder");
	assert_is_ignored(false, "NewFolder/NewFolder/File.txt");
}

void test_attr_ignore__ignore_root(void)
{
	cl_git_rewritefile("attr/.gitignore", "/\n\n/NewFolder\n/NewFolder/NewFolder");

	assert_is_ignored(false, "File.txt");
	assert_is_ignored(true, "NewFolder");
	assert_is_ignored(true, "NewFolder/NewFolder");
	assert_is_ignored(true, "NewFolder/NewFolder/File.txt");
}

void test_attr_ignore__full_paths(void)
{
	cl_git_rewritefile("attr/.gitignore", "Folder/*/Contained");

	assert_is_ignored(true, "Folder/Middle/Contained");
	assert_is_ignored(false, "Folder/Middle/More/More/Contained");

	cl_git_rewritefile("attr/.gitignore", "Folder/**/Contained");

	assert_is_ignored(true, "Folder/Middle/Contained");
	assert_is_ignored(true, "Folder/Middle/More/More/Contained");

	cl_git_rewritefile("attr/.gitignore", "Folder/**/Contained/*/Child");

	assert_is_ignored(true, "Folder/Middle/Contained/Happy/Child");
	assert_is_ignored(false, "Folder/Middle/Contained/Not/Happy/Child");
	assert_is_ignored(true, "Folder/Middle/More/More/Contained/Happy/Child");
	assert_is_ignored(false, "Folder/Middle/More/More/Contained/Not/Happy/Child");
}

void test_attr_ignore__leading_stars(void)
{
	cl_git_rewritefile(
		"attr/.gitignore",
		"*/onestar\n"
		"**/twostars\n"
		"*/parent1/kid1/*\n"
		"**/parent2/kid2/*\n");

	assert_is_ignored(true, "dir1/onestar");
	assert_is_ignored(true, "dir1/onestar/child"); /* in ignored dir */
	assert_is_ignored(false, "dir1/dir2/onestar");

	assert_is_ignored(true, "dir1/twostars");
	assert_is_ignored(true, "dir1/twostars/child"); /* in ignored dir */
	assert_is_ignored(true, "dir1/dir2/twostars");
	assert_is_ignored(true, "dir1/dir2/twostars/child"); /* in ignored dir */
	assert_is_ignored(true, "dir1/dir2/dir3/twostars");

	assert_is_ignored(true, "dir1/parent1/kid1/file");
	assert_is_ignored(true, "dir1/parent1/kid1/file/inside/parent");
	assert_is_ignored(false, "dir1/dir2/parent1/kid1/file");
	assert_is_ignored(false, "dir1/parent1/file");
	assert_is_ignored(false, "dir1/kid1/file");

	assert_is_ignored(true, "dir1/parent2/kid2/file");
	assert_is_ignored(true, "dir1/parent2/kid2/file/inside/parent");
	assert_is_ignored(true, "dir1/dir2/parent2/kid2/file");
	assert_is_ignored(true, "dir1/dir2/dir3/parent2/kid2/file");
	assert_is_ignored(false, "dir1/parent2/file");
	assert_is_ignored(false, "dir1/kid2/file");
}

void test_attr_ignore__skip_gitignore_directory(void)
{
	cl_git_rewritefile("attr/.git/info/exclude", "/NewFolder\n/NewFolder/NewFolder");
	p_unlink("attr/.gitignore");
	cl_assert(!git_path_exists("attr/.gitignore"));
	p_mkdir("attr/.gitignore", 0777);
	cl_git_mkfile("attr/.gitignore/garbage.txt", "new_file\n");

	assert_is_ignored(false, "File.txt");
	assert_is_ignored(true, "NewFolder");
	assert_is_ignored(true, "NewFolder/NewFolder");
	assert_is_ignored(true, "NewFolder/NewFolder/File.txt");
}

void test_attr_ignore__expand_tilde_to_homedir(void)
{
	git_buf cleanup = GIT_BUF_INIT;
	git_config *cfg;

	assert_is_ignored(false, "example.global_with_tilde");

	cl_fake_home(&cleanup);

	/* construct fake home with fake global excludes */
	cl_git_mkfile("home/globalexclude", "# found me\n*.global_with_tilde\n");

	cl_git_pass(git_repository_config(&cfg, g_repo));
	cl_git_pass(git_config_set_string(cfg, "core.excludesfile", "~/globalexclude"));
	git_config_free(cfg);

	git_attr_cache_flush(g_repo); /* must reset to pick up change */

	assert_is_ignored(true, "example.global_with_tilde");

	cl_git_pass(git_futils_rmdir_r("home", NULL, GIT_RMDIR_REMOVE_FILES));

	cl_fake_home_cleanup(&cleanup);

	git_attr_cache_flush(g_repo); /* must reset to pick up change */

	assert_is_ignored(false, "example.global_with_tilde");
}
