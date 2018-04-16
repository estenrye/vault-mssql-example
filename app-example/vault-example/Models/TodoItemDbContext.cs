using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace vault_example.Models
{
    public class TodoItemDbContext : DbContext
    {
        public TodoItemDbContext(DbContextOptions options, ITodoItemDesignTimeDbContextFactory contextFactory) : 
            base(contextFactory==null ? options : contextFactory.GetDbContextOptions())
        {
        }

        public DbSet<TodoItem> TodoItems { get; set; }
    }
}
