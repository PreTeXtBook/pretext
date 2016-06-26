Contributing to MathBook XML
----------------------------

Thanks for your interest in making MathBook XML better.  Contributions from users are an important part of its development.  The following suggestions are meant to make the process of creating and accepting a contribution easier for you, and easier for the maintainers.

*  Use the [mathbook-xml-support](https://groups.google.com/forum/#!forum/mathbook-xml-support) group to float your idea before starting.  You will get some good feedback that will make your contribution better and you may get some cautions that will save you some effort.
*  Pull requests on GitHub are the easiest way to contribute and are really the only practical way for us to review, test, and incorporate your work.  If you are new to Git, there is lots of information on the Internet, and some of it is even helpful and accurate.  You can also read a guide we put together, [Git for Authors](http://mathbook.pugetsound.edu/gfa/html/). Despite the title, it has general principles and techniques that work equally well for software.
*  **Always** begin a new branch for a contribution.  And keep topically distinct contributions on different branches.  Small and compact is better than large and diverse.
*  Pull frequently from the main line of development for official MathBook XML (`dev` at this writing) to update current progress.  Then **rebase** your topic branch onto the tip of this official branch.
```
git checkout dev
git pull origin dev
git checkout topic
git rebase dev
```
*  In particular, **do not merge** `dev` into your `topic` branch, that makes our job harder when we add your work into the official repository.
*  Once you have your branch in good shape, be sure you update `dev` one last time and rebase onto the tip of `dev`.  Then make a pull request with that branch.
*  While your work is being reviewed, do not add any new commits to your branch, and do not rebase it again, unless you are asked to add changes.  If you later need to build on your work, then say so in the discussion area and we can plot how to accomodate that.  But it would be better to not make a pull request until you are completely finished with a task.
*  We are likely to combine your commits, and maybe even then distribute them into logical chunks.  We will edit your commit messages, deleting anything beyond a single line (so do not spend time on that).
*  We will preserve your authorship, and mark the commit(s) with the pull request number so there is a record of where it came from and how.
*  Once we incorporate your work into the mainline of the official repository, then you can pull those changes and delete your topic branch.

(2016-06-25)
