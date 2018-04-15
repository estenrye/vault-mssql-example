using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace vault_example.Models
{
    public interface ITodoItemDesignTimeDbContextFactory : IDesignTimeDbContextFactory<TodoItemDbContext>
    {
        DbContextOptions<TodoItemDbContext> GetDbContextOptions();
    }
}
