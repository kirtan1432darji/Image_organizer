using AutoMapper;
using AI.ScreenshotOrganizer.Application.Features.Auth.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Categories.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Application.Features.Tags.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Common.Mappings;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<User, UserDto>();

        CreateMap<Category, CategoryDto>()
            .ForMember(d => d.SubCategories, opt => opt.MapFrom(s => s.SubCategories));

        CreateMap<Category, CategorySummaryDto>();

        CreateMap<Tag, TagDto>();
        CreateMap<Tag, TagSummaryDto>();

        CreateMap<Screenshot, ScreenshotDto>()
            .ForMember(d => d.Categories, opt => opt.MapFrom(s => s.ScreenshotCategories.Select(sc => sc.Category)))
            .ForMember(d => d.Tags, opt => opt.MapFrom(s => s.ScreenshotTags.Select(st => st.Tag)))
            .ForMember(d => d.Category, opt => opt.MapFrom(s => s.Category))
            .ForMember(d => d.SubCategory, opt => opt.MapFrom(s => s.SubCategory));
    }
}
